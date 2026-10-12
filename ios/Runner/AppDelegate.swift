import AuthenticationServices
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 트레이너 보고 알림(flutter_local_notifications). FlutterAppDelegate 가 받은
    // 알림 이벤트를 플러그인에 넘긴다 — 앱이 떠 있을 때도 배너가 보이고, 눌러서
    // 켜진 것을 알 수 있다. 실행이 끝나기 전에 걸어야 누른 알림을 놓치지 않는다.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 심박 관찰자. 앱이 사는 동안 붙들고 있어야 쿼리가 살아 있다.
  private var heartRate: HeartRateObserver?
  private var timing: TimingBridge?
  private var nearby: NearbyInvite?
  private var restAlarm: RestAlarm?
  private let webSignIn = WebSignIn()

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    heartRate = HeartRateObserver(messenger: engineBridge.applicationRegistrar.messenger())
    timing = TimingBridge(messenger: engineBridge.applicationRegistrar.messenger())
    nearby = NearbyInvite(messenger: engineBridge.applicationRegistrar.messenger())
    restAlarm = RestAlarm(messenger: engineBridge.applicationRegistrar.messenger())
    let webSignIn = self.webSignIn

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
      if call.method == "signIn" {
        guard let raw = (call.arguments as? [String: Any])?["url"] as? String,
          let url = URL(string: raw), url.scheme == "https"
        else { return result(FlutterError(code: "url", message: nil, details: nil)) }
        webSignIn.start(url, result: result)
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

/// 웹 로그인(카카오, 아이폰의 Google)을 앱 안의 로그인 창으로 연다.
///
/// 기본 브라우저로 내보내면 심사가 4.0(로그인하러 앱 밖으로 나간다)으로 돌려보낸다.
/// 서버가 setpad://signin?… 으로 돌려보내면 창이 그 주소를 받아 닫히고, 그 주소를
/// 그대로 Dart 로 넘긴다(링크 처리를 거치지 않는다). 사람이 닫으면 nil 이다.
final class WebSignIn: NSObject, ASWebAuthenticationPresentationContextProviding {
  /// 창이 떠 있는 동안 붙들고 있어야 한다. 놓으면 창이 닫힌다.
  private var session: ASWebAuthenticationSession?
  private var generation = 0

  func start(_ url: URL, result: @escaping FlutterResult) {
    // 앞의 창이 남아 있으면 닫는다 — 그 호출은 nil 로 끝난다.
    session?.cancel()
    generation += 1
    let mine = generation
    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "setpad") {
      [weak self] callback, error in
      DispatchQueue.main.async {
        if self?.generation == mine { self?.session = nil }
        if let callback { return result(callback.absoluteString) }
        if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
          return result(nil)
        }
        result(FlutterError(code: "failed", message: error?.localizedDescription, details: nil))
      }
    }
    session.presentationContextProvider = self
    self.session = session
    if !session.start() {
      self.session = nil
      result(FlutterError(code: "failed", message: "start", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
  }
}
