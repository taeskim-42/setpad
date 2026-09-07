import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 심박 관찰자. 앱이 사는 동안 붙들고 있어야 쿼리가 살아 있다.
  private var heartRate: HeartRateObserver?
  private var localAi: LocalAiBridge?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    heartRate = HeartRateObserver(messenger: engineBridge.applicationRegistrar.messenger())
    localAi = LocalAiBridge(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
