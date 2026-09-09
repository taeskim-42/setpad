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
        let player = try AVAudioPlayer(data: wave(seconds: 60.0 / Double(bpm), frequency: 1100, tone: 0.035))
        player.numberOfLoops = -1; player.volume = 0.45; player.prepareToPlay(); guard player.play() else { throw NSError(domain: "setpad.timing", code: 1) }; beat = player
      }
    }
    if let cueName {
      cue?.stop()
      let player = try AVAudioPlayer(data: wave(seconds: cueName == "complete" ? 0.5 : 0.15,
        frequency: cueName == "rest" ? 520 : cueName == "ready" ? 760 : 1320,
        tone: cueName == "complete" ? 0.4 : 0.1))
      player.volume = 0.5; guard player.play() else { throw NSError(domain: "setpad.timing", code: 2) }; cue = player
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

  private func wave(seconds: Double, frequency: Double, tone: Double) -> Data {
    let rate = 22050, frames = Int(seconds * Double(rate)), sounding = Int(tone * Double(rate))
    var data = Data()
    func text(_ value: String) { data.append(contentsOf: value.utf8) }
    func word<T: FixedWidthInteger>(_ value: T) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
    text("RIFF"); word(UInt32(36 + frames * 2)); text("WAVEfmt "); word(UInt32(16))
    word(UInt16(1)); word(UInt16(1)); word(UInt32(rate)); word(UInt32(rate * 2)); word(UInt16(2)); word(UInt16(16))
    text("data"); word(UInt32(frames * 2))
    for i in 0..<frames {
      let envelope = i < sounding ? min(1, Double(i) / 40) * (1 - Double(i) / Double(sounding)) : 0
      word(Int16(sin(Double(i) * frequency * 2 * .pi / Double(rate)) * envelope * 22000))
    }
    return data
  }
}
