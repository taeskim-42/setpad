import AVFoundation
import Flutter
import UIKit

@MainActor
final class TimingBridge {
  private let channel: FlutterMethodChannel
  private var beat: AVAudioPlayer?
  private var cue: AVAudioPlayer?
  private var tempo: Int?
  private var observers: [NSObjectProtocol] = []
  private let speech = AVSpeechSynthesizer()
  private var pendingSpeech: Task<Void, Never>?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "setpad/timing", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterMethodNotImplemented); return }
      let args = call.arguments as? [String: Any] ?? [:]
      if call.method == "speak" {
        self.speak(args["text"] as? String ?? "", locale: args["locale"] as? String ?? "en")
        result(nil)
        return
      }
      guard call.method == "configure" else { result(FlutterMethodNotImplemented); return }
      do {
        try self.configure(active: args["active"] as? Bool ?? false,
                           bpm: args["bpm"] as? Int, cueName: args["cue"] as? String)
        result(nil)
      } catch {
        self.stop()
        result(FlutterError(code: "audioUnavailable", message: nil, details: nil))
      }
    }
    for name in [UIApplication.willResignActiveNotification, AVAudioSession.interruptionNotification] {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        Task { @MainActor in self?.stop(); self?.channel.invokeMethod("interrupted", arguments: nil) }
      })
    }
  }

  /// Match Tempo: click, then count half a beat later (at most one second).
  private func speak(_ text: String, locale: String) {
    guard !text.isEmpty, tempo != nil, pendingSpeech == nil, !speech.isSpeaking else { return }
    let countOffset = min(30.0 / Double(tempo!), 1.0)
    let countRemaining = beat.map { max(0, countOffset - $0.currentTime) } ?? 0
    let cueRemaining = cue.flatMap { $0.isPlaying ? max(0, $0.duration - $0.currentTime) : nil } ?? 0
    let delay = max(countRemaining, cueRemaining)
    pendingSpeech = Task { @MainActor [weak self] in
      if delay > 0 {
        try? await Task.sleep(nanoseconds: UInt64((delay + 0.005) * 1_000_000_000))
      }
      guard !Task.isCancelled, let self else { return }
      self.pendingSpeech = nil
      guard self.tempo != nil, !self.speech.isSpeaking else { return }
      let utterance = AVSpeechUtterance(string: text)
      utterance.voice = AVSpeechSynthesisVoice(language: locale)
        ?? AVSpeechSynthesisVoice(language: Locale.current.identifier)
      utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.15
      self.speech.speak(utterance)
    }
  }

  private func cancelSpeech() {
    pendingSpeech?.cancel(); pendingSpeech = nil
    speech.stopSpeaking(at: .immediate)
  }

  private func configure(active: Bool, bpm: Int?, cueName: String?) throws {
    let session = AVAudioSession.sharedInstance()
    if active || cueName != nil {
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
    }
    UIApplication.shared.isIdleTimerDisabled = active
    let validTempo = active ? bpm.flatMap { (20...300).contains($0) ? $0 : nil } : nil
    if validTempo != tempo || !active {
      cancelSpeech()
      beat?.stop(); beat = nil; tempo = validTempo
      if let bpm = validTempo {
        let player = try AVAudioPlayer(data: wave(Self.click, length: 60.0 / Double(bpm)))
        player.numberOfLoops = -1; player.prepareToPlay(); guard player.play() else { throw NSError(domain: "setpad.timing", code: 1) }; beat = player
      }
    }
    if let cueName {
      cue?.stop()
      let player = try AVAudioPlayer(data: wave(Self.cue(cueName)))
      guard player.play() else { throw NSError(domain: "setpad.timing", code: 2) }; cue = player
    } else if !active {
      cue?.stop(); cue = nil
      try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
  }

  private func stop() {
    cancelSpeech()
    beat?.stop(); beat = nil; cue?.stop(); cue = nil; tempo = nil
    UIApplication.shared.isIdleTimerDisabled = false
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
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
