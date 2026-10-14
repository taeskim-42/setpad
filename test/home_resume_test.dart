// 홈이 앱 복귀를 다루는 법 — 제어 센터·Face ID(inactive)에서 돌아올 때는 올리지 않고,
// 정말 내렸다 올 때만 밀린 기록을 올린다. 올리기는 한 번에 하나다.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:setpad/account.dart';
import 'package:setpad/editor.dart';
import 'package:setpad/main.dart';
import 'package:setpad/notes.dart';

void main() {
  testWidgets('inactive 복귀는 올리지 않고, 내렸다 오면 한 번 — 빨리 두 번 와도 동시에 하나만', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('setpad-resume');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    // Yesterday's gym workout with a set — not an empty visit the home tidies away.
    final note = store.create(
      gymId: 'g1',
      at: DateTime.now().subtract(const Duration(days: 1)),
      blocks: [
        ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
      ],
    );
    var posts = 0, open = 0, most = 0;
    Completer<void>? gate;
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        http.Response json(Object body) => http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
        switch (request.url.path) {
          case '/api/me':
            return json({
              'user': {'id': 'u1', 'nickname': 'kim'},
            });
          case '/api/gyms':
            return json({'gyms': [], 'invites': []});
          case '/api/workouts':
            posts++;
            most = ++open > most ? open : most;
            await gate?.future;
            open--;
            return json({'id': 'w1'});
        }
        return json({'routines': [], 'plan': null, 'selling': false});
      }),
    )..token = 'x';
    await tester.pumpWidget(
      SetpadApp(store: store, tags: const Stream.empty(), account: account),
    );
    await tester.pumpAndSettle();
    final base = posts;

    void states(List<AppLifecycleState> all) {
      for (final s in all) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
    }

    const glance = [AppLifecycleState.inactive, AppLifecycleState.resumed];
    const away = [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ];

    // Edited after the upload — it is owed again.
    note.updatedAt = DateTime.now();
    states(glance);
    await tester.pumpAndSettle();
    expect(posts, base, reason: '제어 센터에서 돌아온 것은 복귀가 아니다');

    states(away);
    await tester.pumpAndSettle();
    expect(posts, base + 1);

    note.updatedAt = DateTime.now();
    gate = Completer<void>();
    states(away);
    await tester.pump();
    states(away);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(most, 1, reason: '올리는 중에 또 부르면 겹쳐 보내지 않는다');
    expect(posts, base + 2);
    await tester.pump(const Duration(seconds: 1)); // 저장 디바운스
  });

  testWidgets('편집기에 열린 기록은 5분 안에 올렸으면 복귀해도 다시 올리지 않는다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('setpad-settling');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = NotesStore(directory: dir);
    final note = store.create(
      gymId: 'g1',
      at: DateTime.now().subtract(const Duration(days: 1)),
      blocks: [
        ExerciseBlock('스쿼트', [LoggedSet(value: 80, reps: 5)]),
      ],
    );
    var posts = 0;
    final account = Account(
      storageDir: dir,
      client: MockClient((request) async {
        http.Response json(Object body) => http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
        switch (request.url.path) {
          case '/api/me':
            return json({
              'user': {'id': 'u1', 'nickname': 'kim'},
            });
          case '/api/gyms':
            return json({'gyms': [], 'invites': []});
          case '/api/workouts':
            posts++;
            return json({'id': 'w1'});
        }
        return json({'routines': [], 'plan': null, 'selling': false});
      }),
    )..token = 'x';
    await tester.pumpWidget(
      SetpadApp(store: store, tags: const Stream.empty(), account: account),
    );
    await tester.pumpAndSettle();
    final base = posts;
    store.open.add(note);

    void away() {
      for (final s in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
    }

    note
      ..sentAt = DateTime.now().subtract(const Duration(minutes: 1))
      ..updatedAt = DateTime.now();
    away();
    await tester.pumpAndSettle();
    expect(posts, base, reason: '잠금을 풀 때마다 열린 기록을 다시 올리지 않는다');

    note
      ..sentAt = DateTime.now().subtract(const Duration(minutes: 6))
      ..updatedAt = DateTime.now();
    away();
    await tester.pumpAndSettle();
    expect(posts, base + 1, reason: '5분이 지났으면 올린다');
    store.open.remove(note);
    await tester.pump(const Duration(seconds: 1)); // 저장 디바운스
  });
}
