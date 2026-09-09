import Flutter
import FoundationModels

@available(iOS 26.0, *)
@Generable
private struct ExerciseSetupResponse: Codable {
  @Guide(description: "True only when the input describes one identifiable exercise.")
  var isExercise: Bool
  @Guide(description: "The exercise name in the user's language, without its weight or goal.")
  var name: String
  @Guide(description: "Explicit weight. Extract 80 from '80kg' or '팔십 키로'. Use 0 only if no weight is stated.")
  var weight: Double
  @Guide(description: "Weight unit: kg or lb. Use kg when no weight is stated.")
  var unit: String
  @Guide(description: "Cumulative goal: '100개 채우기', '총 백 개' and '백 개 채울래' each mean 100. Use 0 only when no cumulative goal is stated.")
  var totalReps: Int
  @Guide(description: "Explicit reps in each set, such as 10 in '10회 5세트'. A cumulative goal is NOT reps per set. Use 0 if absent.")
  var repsPerSet: Int
  @Guide(description: "Explicit number of sets, such as 5 in '5세트'. Use 0 if absent.")
  var totalSets: Int
  var repsOnly: Bool
}

@available(iOS 26.0, *)
@Generable
private struct RecordAnswerResponse: Codable {
  @Guide(description: "A concise answer in the user's language grounded in the supplied record facts, or a specific explanation of missing evidence.")
  var text: String
  @Guide(description: "True only when the evidence supports the answer.")
  var hasEvidence: Bool
  @Guide(description: "Exact IDs of the supplied facts supporting the answer. Never invent IDs.")
  var sources: [String]
}

@MainActor
final class LocalAiBridge {
  private let channel: FlutterMethodChannel
  private var generation: Task<Void, Never>?
  private var warmedSession: Any?
  private var warmedInstructions: String?

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
        case "warmQuery": self.warmQuery(args, locale: locale); result(nil)
        case "query": self.query(args, locale: locale, result: result)
        case "answerRecords": self.query(args, locale: locale, answering: true, result: result)
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

  private func warmQuery(_ args: [String: Any], locale: String) {
    guard #available(iOS 26.0, *), status(locale) == "available",
          generation == nil, let instructions = args["instructions"] as? String,
          instructions.count <= 12000 else { return }
    if warmedInstructions == instructions, warmedSession != nil { return }
    let session = LanguageModelSession(instructions: instructions)
    session.prewarm()
    warmedSession = session
    warmedInstructions = instructions
  }

  private func query(_ args: [String: Any], locale: String, answering: Bool = false, result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *), status(locale) == "available" else {
      result(FlutterError(code: "unavailable", message: nil, details: nil)); return
    }
    guard generation == nil else { result(FlutterError(code: "busy", message: nil, details: nil)); return }
    guard let prompt = args["input"] as? String, let instructions = args["instructions"] as? String,
          prompt.count <= 12000 else { result(FlutterError(code: "invalidInput", message: nil, details: nil)); return }
    generation = Task { @MainActor in
      defer { generation = nil }
      do {
        let session: LanguageModelSession
        if !answering, warmedInstructions == instructions,
           let warmed = warmedSession as? LanguageModelSession {
          session = warmed
          warmedSession = nil; warmedInstructions = nil
        } else {
          session = LanguageModelSession(instructions: instructions)
        }
        let data: Data
        if answering {
          let response = try await session.respond(to: prompt, generating: RecordAnswerResponse.self,
            options: GenerationOptions(sampling: .greedy, maximumResponseTokens: 700))
          data = try JSONEncoder().encode(response.content)
        } else {
          let response = try await session.respond(to: prompt,
            options: GenerationOptions(sampling: .greedy, maximumResponseTokens: 1000))
          data = Data(response.content.utf8)
        }
        try Task.checkCancellation()
        result(String(decoding: data, as: UTF8.self))
      } catch { result(FlutterError(code: "generationFailed", message: nil, details: nil)) }
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
        let session = LanguageModelSession(instructions: instructions +
          "\nFor the numeric fields in this generated schema, represent missing numbers as 0. Extract every explicitly stated number into its correct field.")
        let response = try await session.respond(
          to: prompt, generating: ExerciseSetupResponse.self,
          options: GenerationOptions(sampling: .greedy, maximumResponseTokens: 400))
        try Task.checkCancellation()
        let value = response.content
        let data = try JSONSerialization.data(withJSONObject: [
          "isExercise": value.isExercise, "name": value.name, "unit": value.unit,
          "weight": value.weight == 0 ? NSNull() : value.weight as Any,
          "totalReps": value.totalReps == 0 ? NSNull() : value.totalReps as Any,
          "repsPerSet": value.repsPerSet == 0 ? NSNull() : value.repsPerSet as Any,
          "totalSets": value.totalSets == 0 ? NSNull() : value.totalSets as Any,
          "repsOnly": value.repsOnly,
        ])
        result(String(decoding: data, as: UTF8.self))
      } catch {
        result(FlutterError(code: "generationFailed", message: nil, details: nil))
      }
    }
  }
}
