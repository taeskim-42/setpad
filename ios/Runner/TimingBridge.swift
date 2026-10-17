import AVFoundation
import AlarmKit
import Flutter
import SwiftUI
import UIKit

@MainActor
final class TimingBridge {
  private let channel: FlutterMethodChannel
  private var beat: AVAudioPlayer?
  private var cue: AVAudioPlayer?
  private var tempo: Int?
  /// A timer that makes sound runs (a workout run or a set rest; Dart's
  /// keepAlive). The set stage alone keeps the screen on but is not one.
  ///
  /// The audio session is active only while there is sound to make: while
  /// such a timer runs in front, and around each sound. Nothing silent is ever
  /// played to keep the app awake (Apple, Audio Session Programming Guide:
  /// "Use a background task instead of streaming silence to keep the app from
  /// being suspended"); in the background the session goes as soon as nothing
  /// sounds ("If the app is not actively playing or recording audio when it
  /// transitions to the background, deactivate its audio session"), and
  /// boundaries that fall in silence come as local notifications
  /// (lib/boundary_notify.dart).
  private var sounding = false
  private var inBackground = false
  private var releasing: Task<Void, Never>?
  /// Lets Dart put the boundary notifications in place after the app went
  /// to the background, then ends (Apple: "That method has five seconds to
  /// perform any tasks and return").
  private var handoff: UIBackgroundTaskIdentifier = .invalid
  /// Built once and replayed. Creating an AVAudioPlayer per cue put tens of
  /// milliseconds between the moment a phase ends and the sound.
  private var beats: [Int: AVAudioPlayer] = [:]
  private var cues: [String: AVAudioPlayer] = [:]
  private var sessionActive = false
  private var observers: [NSObjectProtocol] = []
  /// Recorded words (Flutter assets, lib/workout_timing.dart countVoice and
  /// phraseVoice), prepared once; the latest [voiceCache] are kept.
  private static let voiceCache = 40
  private var voices: [String: AVAudioPlayer] = [:]
  private var voiceOrder: [String] = []
  /// The word sounding, or the last one.
  private var voice: AVAudioPlayer?
  /// When [voice] stops sounding: its start plus its recording's length. Not
  /// isPlaying, which stays on about 0.1 s past the last sample — the plan of
  /// which counts to say (lib/workout_timing.dart countsSaid) counts on this.
  private var voiceEndsAt = Date.distantPast
  private var voiceSounding: Bool { voice != nil && Date() < voiceEndsAt }
  private var pendingCount: Task<Void, Never>?
  private var pendingPhrase: Task<Void, Never>?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "setpad/timing", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterMethodNotImplemented); return }
      let args = call.arguments as? [String: Any] ?? [:]
      if call.method == "warmUp" {
        self.warmUp()
        result(nil)
        return
      }
      if call.method == "voice" {
        self.playVoice(args["asset"] as? String ?? "", onBeat: args["onBeat"] as? Bool ?? false)
        result(nil)
        return
      }
      if call.method == "keepAlive" {
        self.setSounding(args["on"] as? Bool ?? false)
        result(nil)
        return
      }
      if call.method == "notificationSounds" {
        let assets = args["assets"] as? [String] ?? []
        // Off the main thread: converting reads and writes files.
        DispatchQueue.global(qos: .utility).async {
          let files = NotificationSounds.prepare(assets)
          DispatchQueue.main.async { result(files) }
        }
        return
      }
      guard call.method == "configure" else { result(FlutterMethodNotImplemented); return }
      do {
        try self.configure(active: args["active"] as? Bool ?? false,
                           bpm: args["bpm"] as? Int, cueName: args["cue"] as? String,
                           phase: args["phase"] as? Double ?? 0)
        result(nil)
      } catch {
        self.stop()
        result(FlutterError(code: "audioUnavailable", message: nil, details: nil))
      }
    }
    // Only a real audio interruption (a call, Siri, an alarm) stops the timer.
    // Control Center, Notification Center, Face ID and locking the phone do
    // not: the timer keeps time, its clicks and words keep sounding while they
    // sound, and boundaries in silence come as local notifications.
    observers.append(NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
    ) { [weak self] note in
      let info = note.userInfo ?? [:]
      let type = (info[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init)
      let options = AVAudioSession.InterruptionOptions(rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
      Task { @MainActor in
        guard let self else { return }
        switch type {
        case .began:
          self.stop()
          self.channel.invokeMethod("interrupted", arguments: nil)
        case .ended where options.contains(.shouldResume):
          guard (try? self.activateSession()) != nil else { return }
          self.channel.invokeMethod("resumed", arguments: nil)
          self.settle()
        default: break
        }
      }
    })
    observers.append(NotificationCenter.default.addObserver(
      forName: UIScene.didEnterBackgroundNotification, object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.enteredBackground() }
    })
    observers.append(NotificationCenter.default.addObserver(
      forName: UIScene.willEnterForegroundNotification, object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.willEnterForeground() }
    })
  }

  private func enteredBackground() {
    inBackground = true
    if sounding, handoff == .invalid {
      handoff = UIApplication.shared.beginBackgroundTask(withName: "setpad.timing.notices") { [weak self] in
        Task { @MainActor in self?.endHandoff() }
      }
      Task { @MainActor [weak self] in
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        self?.endHandoff()
      }
    }
    settle()
  }

  private func willEnterForeground() {
    inBackground = false
    endHandoff()
    // Ready before the next sound, so the first beep in front has no lag.
    if sounding, !sessionActive { try? activateSession() }
  }

  private func endHandoff() {
    guard handoff != .invalid else { return }
    UIApplication.shared.endBackgroundTask(handoff)
    handoff = .invalid
  }

  private func setSounding(_ on: Bool) {
    sounding = on
    if on, !inBackground, !sessionActive { try? activateSession() }
    settle()
  }

  /// Something sounds now or is about to: a click loop, a cue, a word.
  private var playing: Bool {
    beat != nil || cue?.isPlaying == true || voiceSounding || pendingCount != nil || pendingPhrase != nil
  }

  /// Deactivates the session once nothing sounds or waits to, when no
  /// sounding timer runs or the app is in the background. The finishing cue
  /// and the words queued behind it play out first.
  private func settle() {
    guard sessionActive, !sounding || inBackground, releasing == nil else { return }
    releasing = Task { @MainActor [weak self] in
      var quietSince: Date?
      while let self, !Task.isCancelled {
        guard self.sessionActive, !self.sounding || self.inBackground else { break }
        // A click loop ends with a configure, which settles again: no need
        // to poll through a whole metronome run.
        if self.beat != nil { break }
        if self.playing {
          quietSince = nil
        } else if let since = quietSince, Date().timeIntervalSince(since) >= 0.3 {
          self.deactivateSession()
          break
        } else if quietSince == nil {
          quietSince = Date()
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
      }
      self?.releasing = nil
    }
  }

  private func deactivateSession() {
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    sessionActive = false
  }

  /// Build the cue players and the first words (both voices) ahead of the
  /// first cue. No sound and no session activation; the category is set first
  /// so preparing cannot duck music.
  private func warmUp() {
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
    for name in ["ready", "work", "rest", "complete"] { _ = try? cuePlayer(name) }
    for sex in ["m", "w"] {
      for n in 1...10 { _ = voicePlayer("assets/voice/count/en/\(sex)/\(n).m4a") }
      for key in ["start", "rest"] { _ = voicePlayer("assets/voice/en/\(sex)/\(key).m4a") }
    }
  }

  private func activateSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    try session.setActive(true)
    sessionActive = true
  }

  /// A count ([onBeat]) matches Tempo: click, then the count half a beat
  /// later (at most one second).
  ///
  /// The count comes from Dart's clock and the click from this player, which
  /// started a few tens of milliseconds later. So when a count arrives the click
  /// it belongs to may not have sounded yet (the loop is near its end): then
  /// wait for that click, not for the one after half a beat ago.
  /// A newer count replaces one still waiting. If the previous word is still
  /// sounding, wait a little for it instead of cutting it off, then give up.
  ///
  /// A phrase ("Round 3, go!", "Rest!") waits for the cue and for the word
  /// sounding or about to; a count arriving meanwhile is dropped.
  private func playVoice(_ asset: String, onBeat: Bool) {
    if onBeat && pendingPhrase != nil { return }
    guard let player = voicePlayer(asset) else { return }
    var countRemaining = 0.0, patience = 3.0
    if onBeat {
      pendingCount?.cancel(); pendingCount = nil
      patience = 0.15
      if let tempo, let beat {
        let period = 60.0 / Double(tempo), half = min(period / 2, 1.0), at = beat.currentTime
        countRemaining = at > period * 0.75 ? period - at + half : max(0, half - at)
        // Start no later than a quarter beat after the planned moment, so a late
        // word never lands on the next click and lateness cannot pile up.
        patience = period * 0.25
      }
    } else {
      pendingPhrase?.cancel(); pendingPhrase = nil
    }
    let cueRemaining = cue.flatMap { $0.isPlaying ? max(0, $0.duration - $0.currentTime) : nil } ?? 0
    let delay = max(countRemaining, cueRemaining)
    let task = Task { @MainActor [weak self] in
      if delay > 0 {
        try? await Task.sleep(nanoseconds: UInt64((delay + 0.005) * 1_000_000_000))
      }
      let giveUp = Date().addingTimeInterval(patience)
      while let self, self.voiceSounding || (!onBeat && self.pendingCount != nil),
            Date() < giveUp, !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 20_000_000)
      }
      guard !Task.isCancelled, let self else { return }
      if onBeat { self.pendingCount = nil } else { self.pendingPhrase = nil }
      if self.voiceSounding {
        if onBeat { return }
        self.voice?.stop()
      }
      if !self.sessionActive, (try? self.activateSession()) == nil {
        NSLog("[timing] no session for voice: \(asset)")
        return
      }
      player.currentTime = 0
      if player.play() {
        self.voice = player
        self.voiceEndsAt = Date().addingTimeInterval(player.duration)
      } else {
        NSLog("[timing] voice did not play: \(asset)")
      }
      self.settle()
    }
    if onBeat { pendingCount = task } else { pendingPhrase = task }
  }

  /// The prepared player of a Flutter asset; nil when it is not in the bundle.
  private func voicePlayer(_ asset: String) -> AVAudioPlayer? {
    voiceOrder.removeAll { $0 == asset }
    voiceOrder.append(asset)
    if let player = voices[asset] { return player }
    if voiceOrder.count > Self.voiceCache { voices[voiceOrder.removeFirst()] = nil }
    let key = FlutterDartProject.lookupKey(forAsset: asset)
    guard let path = Bundle.main.path(forResource: key, ofType: nil),
          let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) else {
      NSLog("[timing] no voice \(asset)")
      return nil
    }
    player.prepareToPlay(); voices[asset] = player
    return player
  }

  private func dropPendingCount() { pendingCount?.cancel(); pendingCount = nil }

  private func cancelVoice() {
    dropPendingCount()
    pendingPhrase?.cancel(); pendingPhrase = nil
    voice?.stop(); voice = nil; voiceEndsAt = .distantPast
  }

  private func configure(active: Bool, bpm: Int?, cueName: String?, phase: Double) throws {
    // The app allows 10 BPM; anything slower than this range is a typo.
    let validTempo = active ? bpm.flatMap { (10...300).contains($0) ? $0 : nil } : nil
    // Only when something is about to sound. A sounding timer in front keeps
    // the session (setSounding): activating costs tens of milliseconds, and
    // doing it per cue was what put a lag before every beep.
    UIApplication.shared.isIdleTimerDisabled = active
    if (cueName != nil || validTempo != nil), !sessionActive {
      do {
        try activateSession()
      } catch {
        // The system may not start audio for an app in the background; the
        // boundary notifications speak then. Not a failure of the timer.
        guard inBackground else { throw error }
        NSLog("[timing] no session in the background: \(error)")
        return
      }
    }
    if validTempo != tempo || !active {
      // Pausing or stopping cuts the voice. A tempo change while running
      // (Tabata work to rest) only drops a count still waiting, and finishing
      // (the complete cue) drops nothing: the last number is allowed to finish.
      if active { dropPendingCount() } else if cueName == nil { cancelVoice() }
      beat?.stop(); beat = nil; tempo = validTempo
      if let bpm = validTempo {
        let player = try beatPlayer(bpm)
        // Start where the timer is inside its beat, not at a fresh click: after a
        // pause or a re-sync the clicks stay on the timer's beat grid.
        player.currentTime = min(max(0, phase), max(0, player.duration - 0.001))
        guard player.play() else { throw NSError(domain: "setpad.timing", code: 1) }
        beat = player
      }
    }
    if let cueName {
      let player = try cuePlayer(cueName)
      if cue !== player { cue?.stop() }
      player.currentTime = 0
      guard player.play() else { throw NSError(domain: "setpad.timing", code: 2) }
      cue = player
      // Build the rest while this one is already sounding, so the first cue of
      // each kind is no slower than the ones after it.
      for name in ["ready", "work", "rest", "complete"] where cues[name] == nil {
        _ = try? cuePlayer(name)
      }
    } else if !active {
      cue?.stop(); cue = nil
      deactivateSession()
    }
    settle()
  }

  private func beatPlayer(_ bpm: Int) throws -> AVAudioPlayer {
    if let player = beats[bpm] { return player }
    let player = try AVAudioPlayer(data: wave(Self.click, length: 60.0 / Double(bpm)))
    player.numberOfLoops = -1; player.prepareToPlay(); beats[bpm] = player
    return player
  }

  private func cuePlayer(_ name: String) throws -> AVAudioPlayer {
    if let player = cues[name] { return player }
    let player = try AVAudioPlayer(data: wave(Self.cue(name)))
    player.prepareToPlay(); cues[name] = player
    return player
  }

  /// Everything off. Dart sends keepAlive again when it needs it (the mux
  /// forgets what it sent on an interruption or a failed call).
  private func stop() {
    cancelVoice()
    beat?.stop(); beat = nil; cue?.stop(); cue = nil; tempo = nil
    sounding = false
    UIApplication.shared.isIdleTimerDisabled = false
    deactivateSession()
  }

  /// Pitch, partials, length and loudness measured from Tempo's cue recordings
  /// (bpm.mp3, prebpm.mp3, end_3s.mp3), so the two apps sound like one.
  private struct Tone { let partials: [(Double, Double)]; let seconds: Double; let decay: Bool; let gain: Double }
  private static let click = Tone(partials: [(655, 1), (1965, 0.1)], seconds: 0.12, decay: true, gain: 0.45)
  private static let ding: [(Double, Double)] = [(1787, 1), (2664, 0.38), (1010, 0.29)]
  private static func cue(_ name: String) -> Tone {
    switch name {
    case "ready": return Tone(partials: [(523, 1), (1568, 0.25)], seconds: 0.08, decay: false, gain: 0.5)
    case "work": return Tone(partials: [(1046, 1), (3138, 0.18)], seconds: 0.22, decay: false, gain: 0.5)
    case "complete": return Tone(partials: ding, seconds: 0.7, decay: false, gain: 0.3)
    default: return Tone(partials: ding, seconds: 0.35, decay: false, gain: 0.25)
    }
  }

  private func wave(_ tone: Tone, length: Double? = nil) -> Data {
    let rate = 22050, frames = Int((length ?? tone.seconds) * Double(rate)), sounding = Int(tone.seconds * Double(rate))
    let scale = tone.partials.reduce(0) { $0 + $1.1 }
    var data = Data()
    func text(_ value: String) { data.append(contentsOf: value.utf8) }
    func word<T: FixedWidthInteger>(_ value: T) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
    text("RIFF"); word(UInt32(36 + frames * 2)); text("WAVEfmt "); word(UInt32(16))
    word(UInt16(1)); word(UInt16(1)); word(UInt32(rate)); word(UInt32(rate * 2)); word(UInt16(2)); word(UInt16(16))
    text("data"); word(UInt32(frames * 2))
    for i in 0..<frames {
      let t = Double(i) / Double(rate)
      let envelope = i >= sounding ? 0 : tone.decay ? exp(-t / (tone.seconds / 4)) : min(1, t / 0.004, (tone.seconds - t) / 0.004)
      let sample = tone.partials.reduce(0.0) { $0 + sin(t * $1.0 * 2 * .pi) * $1.1 } / scale
      word(Int16(sample * envelope * tone.gain * 32000))
    }
    return data
  }
}

// MARK: - Recorded words as notification sounds

/// Copies recorded words (Flutter assets, AAC in .m4a) into Library/Sounds as
/// 16-bit linear PCM CAF, the place and format a local notification can play
/// them from (UNNotificationSound: "Linear PCM, MA4 (IMA/ADPCM), µLaw, aLaw"
/// in "aiff, wav, or caf"; "less than 30 seconds"; "The /Library/Sounds
/// directory of the app's container directory"). Once per file and build.
enum NotificationSounds {
  /// Copies from other builds are dropped once per launch: a recording may
  /// have changed with the app.
  private static var swept = false
  private static let lock = NSLock()

  /// Asset → sound file name, for the assets that are ready.
  static func prepare(_ assets: [String]) -> [String: String] {
    lock.lock(); defer { lock.unlock() }
    let files = FileManager.default
    guard let library = files.urls(for: .libraryDirectory, in: .userDomainMask).first else { return [:] }
    let dir = library.appendingPathComponent("Sounds", isDirectory: true)
    try? files.createDirectory(at: dir, withIntermediateDirectories: true)
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    let prefix = "setpad-\(build)-"
    if !swept {
      swept = true
      for name in (try? files.contentsOfDirectory(atPath: dir.path)) ?? []
      where name.hasPrefix("setpad-") && !name.hasPrefix(prefix) {
        try? files.removeItem(at: dir.appendingPathComponent(name))
      }
    }
    var ready: [String: String] = [:]
    for asset in Set(assets) {
      let base = (asset as NSString).deletingPathExtension.replacingOccurrences(of: "/", with: "_")
      let name = "\(prefix)\(base).caf"
      let target = dir.appendingPathComponent(name)
      if files.fileExists(atPath: target.path) || convert(asset, to: target) { ready[asset] = name }
    }
    return ready
  }

  private static func convert(_ asset: String, to target: URL) -> Bool {
    let key = FlutterDartProject.lookupKey(forAsset: asset)
    guard let path = Bundle.main.path(forResource: key, ofType: nil) else { return false }
    let partial = FileManager.default.temporaryDirectory.appendingPathComponent(target.lastPathComponent)
    try? FileManager.default.removeItem(at: partial)
    do {
      try write(from: URL(fileURLWithPath: path), to: partial)
      try FileManager.default.moveItem(at: partial, to: target)
      return true
    } catch {
      NSLog("[timing] no notification sound for \(asset): \(error)")
      try? FileManager.default.removeItem(at: partial)
      return false
    }
  }

  /// Its own function so both files are closed when it returns.
  private static func write(from source: URL, to target: URL) throws {
    let input = try AVAudioFile(forReading: source)
    let format = input.processingFormat
    // Longer plays the default sound instead; the phrases are 1–2 s.
    guard input.length > 0, Double(input.length) / format.sampleRate < 29 else {
      throw NSError(domain: "setpad.timing", code: 3)
    }
    let output = try AVAudioFile(forWriting: target, settings: [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: format.sampleRate,
      AVNumberOfChannelsKey: format.channelCount,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
    ], commonFormat: format.commonFormat, interleaved: format.isInterleaved)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(input.length)) else {
      throw NSError(domain: "setpad.timing", code: 4)
    }
    try input.read(into: buffer)
    try output.write(from: buffer)
  }
}

// MARK: - 손목까지 알리는 휴식 끝 (AlarmKit)

/// 심박이 내려와 휴식이 끝났을 때 손목까지 알린다.
///
/// 워치 앱 없이 손목을 울리는 문서상의 길이 이것이다 — "The system forwards the
/// alert presentation to a paired watch (if any) to notify people when an alarm
/// is alerting."(Scheduling an alarm with AlarmKit). 기본 운동 앱이 워치 화면을
/// 차지하고 있어도 경보는 시스템이 띄운다. 폰 화면이 켜져 있을 때도 워치로
/// 넘어가는지와 지연은 문서에 없어 실기기로 잰다.
///
/// 경보는 끌 때까지 울리는 것이라 몇 초 뒤 스스로 끈다 — 알리는 것이 목적이다.
@MainActor
final class RestAlarm {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "setpad/rest_alarm", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 26.1, *) else { return result(false) }
      switch call.method {
      case "authorize":
        Task { @MainActor in result(await Self.authorize()) }
      case "ring":
        let title = (call.arguments as? [String: Any])?["title"] as? String ?? ""
        Task { @MainActor in result(await Self.ring(title)) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 26.1, *)
  private static func authorize() async -> Bool {
    switch AlarmManager.shared.authorizationState {
    case .authorized: return true
    case .denied: return false
    default: return (try? await AlarmManager.shared.requestAuthorization()) == .authorized
    }
  }

  // 경보 화면의 새 생성자(시스템이 끄기 단추를 붙인다)가 26.1 부터다.
  @available(iOS 26.1, *)
  private static func ring(_ title: String) async -> Bool {
    guard !title.isEmpty, await authorize() else { return false }
    let id = UUID()
    let alert = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: title),
      secondaryButton: nil, secondaryButtonBehavior: nil)
    let attributes = AlarmAttributes<RestAlarmMetadata>(
      presentation: AlarmPresentation(alert: alert), metadata: nil, tintColor: .red)
    do {
      // 지금 울린다. 고정 시각이 과거면 거절될 수 있어 1초 뒤로 둔다.
      _ = try await AlarmManager.shared.schedule(
        id: id,
        configuration: .alarm(schedule: .fixed(Date().addingTimeInterval(1)), attributes: attributes))
    } catch {
      NSLog("[휴식 경보] 예약 실패: \(error)")
      return false
    }
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 5_000_000_000)
      try? AlarmManager.shared.stop(id: id)
      try? AlarmManager.shared.cancel(id: id)
    }
    return true
  }
}

@available(iOS 26.0, *)
struct RestAlarmMetadata: AlarmMetadata {}
