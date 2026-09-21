import Flutter
import GroupActivities
import UIKit

/// 아이폰 둘을 가까이 대서 초대를 건넨다 — Apple 의 "SharePlay over AirDrop".
///
/// **NFC 가 아니다.** 일반 앱은 아이폰끼리 NFC 로 말할 수 없다(Core NFC 는 태그를 읽고
/// 쓰는 것이다). 공개된 길은 이것이다: 초대를 띄운 사람이 이 화면을 연 채 두 아이폰을
/// 가까이 대면 시스템이 시작을 묻고, 상대 아이폰에는 참여를 묻는다. 둘 다 눌러야 하므로
/// 옆 사람에게 몰래 붙을 수 없다.
///
/// **건네는 것은 한 번 쓰는 초대 토큰뿐이다.** 로그인 토큰도 운동 기록도 가지 않는다.
/// 받은 쪽 앱이 그 토큰으로 서버에 참여를 요청하고, "같이 운동 중" 은 서버가 확정한
/// 뒤의 일이다 — 코드로 들어올 때와 같은 초대, 같은 길이다.
@available(iOS 17.0, *)
struct SetpadInvite: GroupActivity {
  static let activityIdentifier = "com.tskim.workoutlog.invite"

  /// "session"(같이 하기) 또는 "plan"(공동 루틴).
  let kind: String
  let token: String
  let title: String

  var metadata: GroupActivityMetadata {
    var meta = GroupActivityMetadata()
    meta.title = title
    meta.type = .workoutTogether
    return meta
  }
}

final class NearbyInvite: NSObject {
  private let channel: FlutterMethodChannel
  private var watching: Task<Void, Never>?
  /// 내가 띄운 초대. 내 것이 나에게 돌아와도 참여하려 들지 않게 기억한다.
  private var offered: String?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "setpad/nearby", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(false) }
      guard #available(iOS 17.0, *) else { return result(false) }
      switch call.method {
      case "supported":
        result(true)
      case "offer":
        let args = call.arguments as? [String: Any]
        guard let kind = args?["kind"] as? String, let token = args?["token"] as? String else {
          return result(false)
        }
        result(self.offer(kind: kind, token: token, title: args?["title"] as? String ?? "setpad"))
      case "clear":
        self.clear()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    if #available(iOS 17.0, *) { watch() }
  }

  private var root: UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
  }

  /// 초대를 화면에 걸어 둔다. 걸려 있는 동안 아이폰을 가까이 대면 시스템이 시작을 묻는다.
  @available(iOS 17.0, *)
  private func offer(kind: String, token: String, title: String) -> Bool {
    guard let root else { return false }
    let provider = NSItemProvider()
    provider.registerGroupActivity(SetpadInvite(kind: kind, token: token, title: title))
    root.activityItemsConfiguration = UIActivityItemsConfiguration(itemProviders: [provider])
    offered = token
    return true
  }

  /// 창을 닫았거나 초대가 끝났다. 걸어 둔 것을 거둔다 — 지나가다 닿은 폰에 묻지 않게.
  private func clear() {
    root?.activityItemsConfiguration = nil
    offered = nil
  }

  /// 시작된 활동을 받는다. 초대를 띄운 쪽에도, 받은 쪽에도 온다.
  @available(iOS 17.0, *)
  private func watch() {
    watching = Task { [weak self] in
      for await session in SetpadInvite.sessions() {
        guard let self else { return }
        let invite = session.activity
        session.join()
        if invite.token != self.offered {
          await MainActor.run {
            self.channel.invokeMethod("received", arguments: ["kind": invite.kind, "token": invite.token])
          }
        }
        // 토큰을 건넸으면 할 일은 끝났다. 세션을 붙들고 있지 않는다 — 기록의 공유는
        // 서버를 거치는 같이 하기가 맡는다.
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        session.leave()
      }
    }
  }

  deinit { watching?.cancel() }
}
