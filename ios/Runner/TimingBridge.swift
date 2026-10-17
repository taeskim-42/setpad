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
  /// Silence looped while the timer runs, so the app is not suspended in the
  /// background during stretches with no sound (rest, a Tabata without BPM).
  /// If App Review rejects it, set this to false: the timer then catches up on
  /// return (Tempo's way) and the signals missed while suspended stay silent.
  private static let keepAliveLoop = true
  private var keepAlive: AVAudioPlayer?
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
    // Control Center, Notification Center, Face ID and locking the phone no
    // longer do: with background audio the timer keeps running and sounding.
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
        default: break
        }
      }
    })
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
      player.currentTime = 0
      if player.play() {
        self.voice = player
        self.voiceEndsAt = Date().addingTimeInterval(player.duration)
      } else {
        NSLog("[timing] voice did not play: \(asset)")
      }
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
    // Activating the session costs tens of milliseconds, so do it once and
    // keep it. Doing it per cue was what put a lag before every beep.
    if (active || cueName != nil), !sessionActive { try activateSession() }
    UIApplication.shared.isIdleTimerDisabled = active
    // Best effort: without it the timer still runs, it only may be suspended
    // in silent stretches, so a failure here never fails the cue or the click.
    if active, Self.keepAliveLoop, keepAlive?.isPlaying != true {
      keepAlive = keepAlive ?? (try? AVAudioPlayer(data: wave(Self.silence, length: 1)))
      keepAlive?.numberOfLoops = -1
      _ = keepAlive?.play()
    } else if !active {
      keepAlive?.stop()
    }
    // The app allows 10 BPM; anything slower than this range is a typo.
    let validTempo = active ? bpm.flatMap { (10...300).contains($0) ? $0 : nil } : nil
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
      try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
      sessionActive = false
    }
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

  private func stop() {
    cancelVoice()
    beat?.stop(); beat = nil; cue?.stop(); cue = nil; tempo = nil; keepAlive?.stop()
    UIApplication.shared.isIdleTimerDisabled = false
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    sessionActive = false
  }

  /// Pitch, partials, length and loudness measured from Tempo's cue recordings
  /// (bpm.mp3, prebpm.mp3, end_3s.mp3), so the two apps sound like one.
  private struct Tone { let partials: [(Double, Double)]; let seconds: Double; let decay: Bool; let gain: Double }
  private static let silence = Tone(partials: [(0, 1)], seconds: 0, decay: false, gain: 0)
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
