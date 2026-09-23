import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// 트레이너 보고 시각 알림.
///
/// 서버가 정한 시각에 에이전트 보고서를 만든다. 그 시각은 이미 설정에 있으니
/// 서버 푸시를 들이지 않고 **기기가 스스로 요일마다 되풀이 알림을 건다.**
/// 웹·테스트처럼 [init] 을 부르지 않았거나 실패한 곳에서는 모두 조용히 아무것도
/// 안 한다 — 알림은 덤이지 보고서의 전제가 아니다.
class AgentAlarm {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<bool>? _started;

  /// 한 곳(main)에서만 듣는다. 단일 구독이라 듣기 전에 온 탭(콜드 스타트)을
  /// 쥐고 있다가 넘긴다 — broadcast 면 main 이 붙기 전에 흘러가 버린다.
  static final _taps = StreamController<String>();

  /// 알림을 눌러 앱이 열리면 그 도장 id 가 흐른다.
  static Stream<String> get taps => _taps.stream;

  /// main 에서 한 번. 권한은 여기서 묻지 않는다 — 트레이너가 아닌 사람까지
  /// 켤 때마다 알림 권한 창을 보게 된다. [ensurePermission] 이 묻는다.
  static Future<void> init() => _started ??= _start();

  static Future<bool> _start() async {
    if (kIsWeb) return false;
    try {
      final ok = await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _tap(r.payload),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _tap(launch!.notificationResponse?.payload);
      }
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static void _tap(String? gymId) {
    if (gymId != null && gymId.isNotEmpty) _taps.add(gymId);
  }

  /// [init] 이 성공했을 때만 true — 아니면 부르는 쪽이 모두 건너뛴다.
  static Future<bool> get _ready async => _started != null && await _started!;

  /// 거절했으면 false. 이미 정해진 답이면 창 없이 그 답을 돌려준다.
  static Future<bool> ensurePermission() async {
    if (!await _ready) return false;
    try {
      final granted = defaultTargetPlatform == TargetPlatform.iOS
          ? await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true)
          : await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 이 도장 알림을 모두 지우고 설정대로 다시 건다.
  ///
  /// 지울 때 id 가 아니라 payload(도장 id)로 찾는다 — 시각을 바꾸면 id 도
  /// 바뀌어서, 옛 id 를 모르면 옛 알림이 남는다.
  static Future<void> sync({
    required String gymId,
    required String gymName,
    required bool enabled,
    required List<int> runMinutes,
    required List<int> weekdays,
  }) async {
    if (!await _ready) return;
    try {
      for (final p in await _plugin.pendingNotificationRequests()) {
        if (p.payload == gymId) await _plugin.cancel(p.id);
      }
      if (!enabled) return;
      final slots = agentAlarmSlots(
        gymId,
        runMinutes,
        weekdays,
        DateTime.now(),
      );
      for (final (:id, :at) in slots) {
        await _plugin.zonedSchedule(
          id,
          '오늘 정리가 준비됐어요',
          '$gymName · 에이전트 보고를 확인해 주세요',
          at,
          _details,
          // Play 가 정확한 알람 권한을 사유로 거절한 전력이 있다
          // (AndroidManifest). 조금 늦게 울려도 되는 알림이라 부정확 알람으로
          // 건다 — 이르게 울리지는 않는다.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: gymId,
        );
      }
    } catch (_) {}
  }

  /// 로그아웃하거나 직원이 아니게 되면. 이 앱이 거는 로컬 알림은 이것뿐이다.
  static Future<void> clearAll() async {
    if (!await _ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'agent_report',
      '에이전트 보고',
      channelDescription: '트레이너 보고가 준비되면 알려요',
    ),
    iOS: DarwinNotificationDetails(),
  );
}

/// 한국 시각. 서버가 이 시각으로 돌기 때문에 기기 시간대와 상관없이 여기에 맞춘다.
///
/// tz 데이터베이스(수백 KB)를 앱과 웹 번들에 싣는 대신 UTC+9 하나로 둔다. 이
/// 값은 **첫 회 날짜를 고르는 데만** 쓰이고, 되풀이는 기기가 이름('Asia/Seoul')과
/// 자기 tz 데이터로 계산한다.
// ponytail: 한국은 1988 년 뒤로 서머타임이 없다. 생기면 timezone 의
// initializeTimeZones + tz.getLocation('Asia/Seoul') 로 바꾼다.
final _seoul = tz.Location('Asia/Seoul', const [], const [], const [
  tz.TimeZone(9 * 3600 * 1000, isDst: false, abbreviation: 'KST'),
]);

/// 이 설정이 거는 알림들: 안정된 id 와 [now] 뒤 처음 울릴 한국 시각.
///
/// [runMinutes] 는 한국 자정부터 분, [weekdays] 는 0=일요일(서버 값 그대로).
/// 보고서를 만들 시간을 주려고 2분 뒤에 울린다 — 23:58 이 넘으면 다음 날로 넘어간다.
@visibleForTesting
List<({int id, tz.TZDateTime at})> agentAlarmSlots(
  String gymId,
  List<int> runMinutes,
  List<int> weekdays,
  DateTime now,
) {
  final today = tz.TZDateTime.from(now, _seoul);
  // 도장마다 다른 id 칸. 웹(JS 숫자)에서도 같은 값이 나오게 작게 접는다.
  final gym = gymId.codeUnits.fold(0, (h, c) => (h * 31 + c) % 200000);
  final slots = <({int id, tz.TZDateTime at})>[];
  for (final w in weekdays.toSet()) {
    for (final m in runMinutes.toSet()) {
      final total = m + 2;
      final day = (w + total ~/ 1440) % 7;
      final minute = total % 1440;
      // DateTime.weekday 는 월=1..일=7, 서버는 일=0.
      final ahead = (day - today.weekday % 7 + 7) % 7;
      var at = tz.TZDateTime(
        _seoul,
        today.year,
        today.month,
        today.day + ahead,
        minute ~/ 60,
        minute % 60,
      );
      if (!at.isAfter(today)) at = at.add(const Duration(days: 7));
      // 7 × 1440 = 10080 칸. 200000 × 10080 은 32비트 int 안에 든다(Android id).
      slots.add((id: gym * 10080 + day * 1440 + minute, at: at));
    }
  }
  return slots;
}
