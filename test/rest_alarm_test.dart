import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/rest_alarm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('setpad/rest_alarm');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('안 되는 곳(iOS 26.1 전, Android, 테스트)에서는 조용히 false', () async {
    expect(await ringRestAlarm('다음 라운드'), isFalse);
    expect(await authorizeRestAlarm(), isFalse);
  });

  test('제목을 실어 울리고, 네이티브의 답을 그대로 돌려준다', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    expect(await ringRestAlarm('다음 라운드 — 심박이 내려왔어요'), isTrue);
    expect(calls.single.method, 'ring');
    expect((calls.single.arguments as Map)['title'], '다음 라운드 — 심박이 내려왔어요');
  });
}
