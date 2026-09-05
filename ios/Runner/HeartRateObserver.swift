import Flutter
import HealthKit

/// 워치가 심박을 쓰면 iOS 가 이 앱을 깨우게 한다.
///
/// **왜 직접 쓰는가.** health 플러그인의 iOS 쪽은 HKSampleQuery 같은 일회성
/// 쿼리만 구현돼 있고 HKObserverQuery 도 enableBackgroundDelivery 도 없다.
/// 새 데이터가 들어올 때 알림을 받는 그 두 개가 정확히 빠져 있어서, 심박으로
/// 휴식을 끊어 주려면 이 부분만 우리가 붙여야 한다.
///
/// **빈도 제한을 실측한다.** HealthKit 백그라운드 전달에는 타입별 최소 갱신
/// 빈도가 있다고 알려져 있으나 심박에 얼마가 걸리는지 문서로 확인하지
/// 못했다. 그래서 깨어날 때마다 직전 깨어남과의 간격을 같이 올려 보낸다 —
/// 이 기능이 성립하는지가 그 숫자에 달려 있다.
final class HeartRateObserver {
  private let store = HKHealthStore()
  private let channel: FlutterMethodChannel
  private var query: HKObserverQuery?
  private var lastWake: Date?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "setpad/heart_rate", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "start": self?.start(result)
      case "stop": self?.stop(result)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func start(_ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(),
          let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
      result(false)
      return
    }
    // 이미 돌고 있으면 두 번 걸지 않는다.
    if query != nil {
      result(true)
      return
    }

    store.requestAuthorization(toShare: [], read: [type]) { [weak self] ok, _ in
      guard let self, ok else {
        DispatchQueue.main.async { result(false) }
        return
      }

      let q = HKObserverQuery(sampleType: type, predicate: nil) {
        [weak self] _, completion, error in
        // completion 을 반드시 부른다. 안 부르면 iOS 가 다음부터 안 깨운다.
        defer { completion() }
        guard let self, error == nil else { return }
        self.report()
      }
      self.query = q
      self.store.execute(q)

      // 앱이 내려가 있어도 깨어나게 한다. immediate 를 달라고 하되, 실제로
      // 얼마나 자주 오는지는 iOS 가 정한다 — 그래서 재는 것이다.
      self.store.enableBackgroundDelivery(for: type, frequency: .immediate) {
        enabled, err in
        DispatchQueue.main.async {
          if let err { NSLog("[심박] 백그라운드 전달 실패: \(err)") }
          result(enabled)
        }
      }
    }
  }

  /// 가장 최근 심박 하나와, 그것이 얼마나 늦게 왔는지를 Dart 로 올린다.
  private func report() {
    guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) {
      [weak self] _, samples, _ in
      guard let self, let s = samples?.first as? HKQuantitySample else { return }
      let now = Date()
      let gap = self.lastWake.map { now.timeIntervalSince($0) }
      self.lastWake = now
      let bpm = s.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
      DispatchQueue.main.async {
        self.channel.invokeMethod("beat", arguments: [
          "bpm": Int(bpm.rounded()),
          // 표본이 측정된 뒤 여기까지 오는 데 걸린 시간.
          "lagSeconds": Int(now.timeIntervalSince(s.endDate).rounded()),
          // 직전 깨어남과의 간격. 빈도 제한이 실제로 얼마인지가 여기 보인다.
          "sinceLastWakeSeconds": gap.map { Int($0.rounded()) } as Any,
        ])
      }
    }
    store.execute(q)
  }

  private func stop(_ result: @escaping FlutterResult) {
    if let q = query { store.stop(q) }
    query = nil
    if let type = HKObjectType.quantityType(forIdentifier: .heartRate) {
      store.disableBackgroundDelivery(for: type) { _, _ in }
    }
    result(true)
  }
}
