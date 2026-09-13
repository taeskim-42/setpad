import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 한 번 해석한 질문은 다시 묻지 않는다.
///
/// **모델이 낸 의도를 그대로 담는다. 풀어낸 날짜는 담지 않는다.** "지난주"
/// 라는 말은 어제와 오늘이 다른 주를 가리키므로, 날짜까지 굳혀 두면 하루만
/// 지나도 못 쓴다. 의도(`periods: ["lastWeek"]`)는 언제 꺼내도 유효하고,
/// 날짜는 꺼낼 때 오늘로 다시 푼다.
///
/// 기기에 남는다. 앱을 껐다 켜도 어제 물어본 말투는 서버에 안 간다.
class QueryCache {
  QueryCache({Directory? directory}) : _override = directory;
  final Directory? _override;
  final _entries = <String, Object?>{};
  Timer? _debounce;
  Future<void> _writes = Future.value();
  bool _loaded = false;

  /// 몇 개까지 들고 있을까. 한 사람이 쓰는 말투는 몇 가지로 수렴하고,
  /// 하나가 몇백 바이트라 이 정도면 파일이 100KB 를 안 넘는다.
  static const limit = 300;

  Future<File> _file() async {
    final dir = _override ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/queries.json');
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = await _file();
      if (!f.existsSync()) return;
      final data = jsonDecode(await f.readAsString());
      if (data is! Map) return;
      for (final entry in data.entries) {
        if (entry.key is String) _entries[entry.key as String] = entry.value;
      }
    } catch (e) {
      // 캐시는 덤이다. 못 읽으면 없는 셈 치고 간다.
      debugPrint('queries.json 을 읽지 못했다: $e');
    }
  }

  Object? operator [](String key) => _entries[key];

  void put(String key, Object? intent) {
    // 다시 넣으면 맨 뒤로 간다 — 오래 안 쓴 것부터 밀려난다.
    _entries.remove(key);
    _entries[key] = intent;
    while (_entries.length > limit) {
      _entries.remove(_entries.keys.first);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), flush);
  }

  Future<void> flush() {
    _debounce?.cancel();
    final payload = jsonEncode(_entries);
    return _writes = _writes.then((_) async {
      try {
        await (await _file()).writeAsString(payload);
      } catch (e) {
        debugPrint('queries.json 을 쓰지 못했다: $e');
      }
    });
  }

  void dispose() => _debounce?.cancel();
}
