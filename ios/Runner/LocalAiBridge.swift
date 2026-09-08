import Flutter
import FoundationModels

@available(iOS 26.0, *)
@Generable
private enum SetupKind: String, Codable { case weight, totalReps, repsPerSet, totalSets }

@available(iOS 26.0, *)
@Generable
private struct SetupParameter: Codable {
  var kind: SetupKind
  @Guide(description: "Exact phrase copied from the user input that states this quantity. Never invent or translate the evidence.")
  var evidence: String
  @Guide(description: "The numeric value explicitly stated by the evidence, including written-out numbers.")
  var value: Double
}

@available(iOS 26.0, *)
@Generable
private struct ExerciseSetupResponse: Codable {
  var isExercise: Bool
  @Guide(description: "Exercise name only, preserving custom machine names. The name reference can resolve abbreviations.")
  var name: String
  @Guide(description: "Only quantities explicitly requested in the INPUT. An exercise or machine name alone has an EMPTY array. No default quantities.")
  var parameters: [SetupParameter]
  @Guide(description: "kg or lb, using the default weight unit unless the input specifies one.")
  var unit: String
  @Guide(description: "Whether the exercise is bodyweight. Do not invent a repetition goal.")
  var repsOnly: Bool
}

@MainActor
final class LocalAiBridge {
  private let channel: FlutterMethodChannel
  private var generation: Task<Void, Never>?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "setpad/local_ai", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      Task { @MainActor in
        guard let self else { return }
        let args = call.arguments as? [String: Any] ?? [:]
        let locale = args["locale"] as? String ?? Locale.current.identifier
        switch call.method {
        case "status": result(self.status(locale))
        case "interpret": self.interpret(args, locale: locale, result: result)
        case "cancel": self.generation?.cancel(); result(nil)
        // Apple manages model downloads and Apple Intelligence settings.
        case "prepare": result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  private func status(_ locale: String) -> String {
    guard #available(iOS 26.0, *) else { return "osUpdateRequired" }
    let model = SystemLanguageModel.default
    switch model.availability {
    case .available:
      return model.supportsLocale(Locale(identifier: locale)) ? "available" : "languageUnavailable"
    case .unavailable(.deviceNotEligible): return "deviceNotEligible"
    case .unavailable(.appleIntelligenceNotEnabled): return "intelligenceDisabled"
    case .unavailable(.modelNotReady): return "modelNotReady"
    @unknown default: return "unavailable"
    }
  }

  private func interpret(_ args: [String: Any], locale: String, result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *), status(locale) == "available" else {
      result(FlutterError(code: "unavailable", message: nil, details: nil)); return
    }
    guard generation == nil else {
      result(FlutterError(code: "busy", message: nil, details: nil)); return
    }
    guard let prompt = args["input"] as? String,
          let instructions = args["instructions"] as? String,
          !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          prompt.count <= 600 else {
      result(FlutterError(code: "invalidInput", message: nil, details: nil)); return
    }
    generation = Task { @MainActor in
      defer { generation = nil }
      do {
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(
          to: prompt, generating: ExerciseSetupResponse.self,
          options: GenerationOptions(sampling: .greedy, maximumResponseTokens: 600))
        try Task.checkCancellation()
        let data = try JSONEncoder().encode(response.content)
        result(String(decoding: data, as: UTF8.self))
      } catch {
        result(FlutterError(code: "generationFailed", message: nil, details: nil))
      }
    }
  }
}
