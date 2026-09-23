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
  private var timing: TimingBridge?
  private var nearby: NearbyInvite?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    heartRate = HeartRateObserver(messenger: engineBridge.applicationRegistrar.messenger())
    timing = TimingBridge(messenger: engineBridge.applicationRegistrar.messenger())
    nearby = NearbyInvite(messenger: engineBridge.applicationRegistrar.messenger())

    // 공유 시트. 글 한 줄(공동 루틴 초대 링크)을 올리는 것이 전부라 플러그인 없이 둔다.
    FlutterMethodChannel(
      name: "setpad/share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      // 링크 열기(개인정보 처리방침 등).
      if call.method == "open" {
        guard let raw = (call.arguments as? [String: Any])?["url"] as? String,
          let url = URL(string: raw), url.scheme == "https"
        else { return result(false) }
        UIApplication.shared.open(url) { opened in result(opened) }
        return
      }
      guard call.method == "share",
        let text = (call.arguments as? [String: Any])?["text"] as? String,
        var top = UIApplication.shared.connectedScenes
          .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first
      else { return result(false) }
      while let presented = top.presentedViewController { top = presented }
      let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
      // iPad 는 말풍선으로 뜬다. 닻이 없으면 죽는다.
      sheet.popoverPresentationController?.sourceView = top.view
      sheet.popoverPresentationController?.sourceRect = CGRect(
        x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
      top.present(sheet, animated: true) { result(true) }
    }
  }
}
