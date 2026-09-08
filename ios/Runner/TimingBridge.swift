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

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "setpad/timing", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, call.method == "configure" else { result(FlutterMethodNotImplemented); return }
      let args = call.arguments as? [String: Any] ?? [:]
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

  private func configure(active: Bool, bpm: Int?, cueName: String?) throws {
    let session = AVAudioSession.sharedInstance()
    if active || cueName != nil {
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
    }
    UIApplication.shared.isIdleTimerDisabled = active
    let validTempo = active ? bpm.flatMap { (20...300).contains($0) ? $0 : nil } : nil
    if validTempo != tempo {
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
