import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/exercises.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/units.dart';

void main() {
  group('세트 줄 읽기', () {
    test('단위를 붙였든 안 붙였든 읽는다', () {
      expect(
        parseSetLine('100kg 20회'),
        const ParsedSet(value: 100, unit: 'kg', reps: 20),
      );
      // 단위를 안 쳤으면 비워 둔다 — 무엇으로 볼지는 쓰는 쪽이 정한다.
      expect(parseSetLine('100 20'), const ParsedSet(value: 100, reps: 20));
    });

    test('숫자가 하나면 횟수다 — 맨몸 운동이 그렇게 적힌다', () {
      expect(parseSetLine('20회'), const ParsedSet(reps: 20));
      expect(parseSetLine('12'), const ParsedSet(reps: 12));
    });

    test('반복 세트는 한 줄로 접힌다', () {
      expect(parseSetLine('100kg 20회 x5')?.count, 5);
      expect(parseSetLine('100kg 20회 5세트')?.count, 5);
      expect(parseSetLine('100kg 20회')?.count, 1);
    });

    test('X16 세트 반복이 20을 넘으면 자르지 않고 거절하고, 이유를 알 수 있다', () {
      expect(parseSetLine('60kg 10회 x20')?.count, 20);
      expect(parseSetLine('60kg 10회 x30'), isNull);
      expect(parseSetLine('맨몸 스쿼트 20회 25세트'), isNull);
      expect(tooManySets('60kg 10회 x30'), isTrue);
      expect(tooManySets('60kg 10회 x20'), isFalse);
      expect(tooManySets('그냥 메모'), isFalse);
    });

    test('자리가 찬 뒤의 수는 덮어쓰지도 버리지도 않고 메모에 친 그대로 남는다', () {
      expect(
        parseSetLine('80 10 8 6'),
        const ParsedSet(value: 80, reps: 10, note: '8 6'),
      );
      expect(
        parseSetLine('10 10 10'),
        const ParsedSet(value: 10, reps: 10, note: '10'),
      );
      // 두 번째 값+단위는 앞의 값을 덮지 않는다.
      expect(
        parseSetLine('80kg 10회 60초 휴식'),
        const ParsedSet(value: 80, unit: 'kg', reps: 10, note: '60초 휴식'),
      );
      expect(
        parseSetLine('5km 25분'),
        const ParsedSet(value: 5, unit: 'km', note: '25분'),
      );
      expect(
        parseSetLine('1분 30초'),
        const ParsedSet(value: 1, unit: 'min', note: '30초'),
      );
      // 두 번째 횟수·세트 표기도 메모다.
      expect(parseSetLine('80 10회 12회')?.note, '12회');
      expect(parseSetLine('80 10 x3 x4')?.count, 3);
      expect(parseSetLine('80 10 x3 x4')?.note, 'x4');
      // 메모 글과 섞여도 친 순서 그대로다.
      expect(parseSetLine('80 10 무릎 8 아픔')?.note, '무릎 8 아픔');
      // 앞 자리가 빈 수는 그대로 채운다.
      expect(parseSetLine('20회 100'), const ParsedSet(value: 100, reps: 20));
    });

    test('키로·킬로는 kg 이다', () {
      expect(
        parseSetLine('80키로 12개'),
        const ParsedSet(value: 80, unit: 'kg', reps: 12),
      );
      expect(parseSetLine('80킬로 12개')?.unit, 'kg');
      expect(parseSetLine('80 키로 12개')?.value, 80);
      // 키로 뒤의 수는 횟수라 하나씩 민다.
      expect(bumpLastNumber('80키로 10', 1), '80키로 11');
    });

    test('쉼표 소수와 천 단위', () {
      expect(
        parseSetLine('22,5kg 10'),
        const ParsedSet(value: 22.5, unit: 'kg', reps: 10),
      );
      expect(parseSetLine('22,5 10')?.value, 22.5);
      expect(parseSetLine('1,000m')?.value, 1000);
      expect(parseSetLine('1,000m')?.unit, 'm');
      expect(parseSetLine('1,200 3')?.value, 1200);
    });

    test('수+단위 뒤의 조사·접미사는 떼고 읽는다', () {
      expect(
        parseSetLine('80kg에 10개'),
        const ParsedSet(value: 80, unit: 'kg', reps: 10),
      );
      expect(parseSetLine('10회씩 3세트'), const ParsedSet(reps: 10, count: 3));
      expect(parseSetLine('20kg짜리 12')?.value, 20);
      expect(parseSetLine('80키로로 5개')?.value, 80);
      expect(parseSetLine('80kg으로 5회')?.unit, 'kg');
      expect(parseSetLine('80 kg에 10개')?.value, 80);
    });

    test('숫자를 다 먹고 남은 것이 메모다', () {
      final parsed = parseSetLine('100kg 20회 마지막에 힘들었음');
      expect(parsed?.value, 100);
      expect(parsed?.reps, 20);
      expect(parsed?.note, '마지막에 힘들었음');
      expect(parseSetLine('20회 어깨 불편')?.note, '어깨 불편');
    });

    test('친 단위를 그대로 남긴다 — 몰래 환산하지 않는다', () {
      // 예전에는 lb 를 kg 으로 바꿔 저장했다. 파운드로 운동하는 사람에게는
      // 자기가 친 숫자가 사라지는 셈이라 못 쓴다.
      final p = parseSetLine('225lb 5회')!;
      expect(p.value, 225);
      expect(p.unit, 'lb');
    });

    test('무게 말고 거리·시간도 읽는다', () {
      expect(parseSetLine('5km')?.unit, 'km');
      expect(parseSetLine('400m')?.value, 400);
      expect(parseSetLine('400m')?.unit, 'm');
      expect(parseSetLine('60초')?.unit, 's');
      expect(parseSetLine('3분')?.unit, 'min');
      expect(parseSetLine('1mi')?.unit, 'mi');
    });

    test('단위를 여러 언어로 쳐도 같은 것으로 읽는다', () {
      for (final t in ['100kg', '100킬로', '100公斤', '100キロ']) {
        expect(parseSetLine(t)?.unit, 'kg', reason: t);
      }
      for (final t in ['225lb', '225lbs', '225파운드', '225磅']) {
        expect(parseSetLine(t)?.unit, 'lb', reason: t);
      }
      for (final t in ['30초', '30s', '30sec', '30秒']) {
        expect(parseSetLine(t)?.unit, 's', reason: t);
      }
    });

    test('숫자가 없으면 세트가 아니다', () {
      expect(parseSetLine('그냥 메모'), isNull);
      expect(parseSetLine('   '), isNull);
    });

    test('소수 무게도 읽는다', () {
      expect(parseSetLine('22.5kg 12회')?.value, 22.5);
    });
  });

  group('자동완성', () {
    const pool = ['벤치프레스', '인클라인 벤치프레스', '덤벨 프레스', '레그프레스'];

    test('앞글자 일치가 먼저다', () {
      expect(suggest('벤', pool), ['벤치프레스', '인클라인 벤치프레스']);
    });

    test('조사를 뗀다, 남는 게 두 글자 아래면 안 뗀다', () {
      expect(stripParticle('벤치프레스는'), '벤치프레스');
      expect(stripParticle('스쿼트가'), '스쿼트');
      expect(stripParticle('데드리프트의'), '데드리프트');
      expect(stripParticle('데드'), '데드'); // "드" 를 조사로 보면 안 된다
      expect(stripParticle('벤치랑'), '벤치');
      expect(stripParticle('스쾃이랑'), '스쾃');
    });

    test('수사 한글', () {
      expect(koreanNumber('팔십'), 80);
      expect(koreanNumber('백'), 100);
      expect(koreanNumber('백이십'), 120);
      expect(koreanNumber('오'), 5);
      expect(koreanNumber('구백구십구'), 999);
      expect(koreanNumber('킬로'), isNull);
    });

    test('글이 지목한 운동 — 긴 키부터, 찾은 자리는 지운다', () {
      const pool = ['벤치프레스', '레그프레스', '오버헤드프레스', '랫풀다운', '푸시업', '스쿼트'];
      expect(namedExercises('오버헤드 프레스 세트 수', pool), ['오버헤드프레스']);
      expect(namedExercises('이번 주 bench press 평균', pool), ['벤치프레스']);
      expect(namedExercises('lat pulldown 총량', pool), ['랫풀다운']);
      expect(namedExercises('pushup 평균', pool), ['푸시업']);
      expect(namedExercises('벤치 프레스 PR', pool), ['벤치프레스']);
      expect(namedExercises('벤치 최고', pool), ['벤치프레스']); // 접두는 낱말 단계
      expect(namedExercises('프레스 최고', pool), isEmpty); // 여럿에 닿는 낱말은 지목이 아니다
      expect(namedExercises('벤치프레스랑 스쿼트 최고', pool), ['벤치프레스', '스쿼트']);
      expect(namedExercises('스쿼트 벤치 요즘 어때', pool), ['스쿼트', '벤치프레스']); // 키 + 접두
      expect(namedExercises('가장 자주 한 운동 세 개', pool), isEmpty);
      // 두 글자 로마자는 이름 속 글자일 뿐이다 — PR 은 bench press 가 아니다.
      expect(namedExercises('스쿼트 PR', ['스쿼트', '벤치프레스']), ['스쿼트']);
      // 적은 순서 그대로다 — 키 길이 순이 아니다. 표의 열과 차이의 부호가 이것을 따른다.
      const pair = ['벤치프레스', '바벨로우'];
      expect(namedExercises('벤치 vs 바벨로우', pair), ['벤치프레스', '바벨로우']);
      expect(namedExercises('바벨로우 vs 벤치프레스 기록 비교', pair), ['바벨로우', '벤치프레스']);
    });

    test('스쾃은 스쿼트다 — 오타가 아니라 표기법이다', () {
      expect(suggest('스쾃', ['스쿼트', '레그프레스']), ['스쿼트']);
    });

    test('이름 안쪽 단어로도 찾힌다', () {
      expect(suggest('덤벨', pool), ['덤벨 프레스']);
      expect(suggest('프레스', pool).first, '덤벨 프레스');
    });

    test('빈 입력에는 아무것도 주지 않는다', () {
      expect(suggest('', pool), isEmpty);
      expect(suggest('   ', pool), isEmpty);
    });

    test('없는 것은 없다고 한다', () {
      expect(suggest('요가', pool), isEmpty);
    });
  });

  group('표시', () {
    test('소수점이 필요 없으면 뗀다', () {
      expect(formatValue(100, 'kg'), '100kg');
      expect(formatValue(22.5, 'kg'), '22.5kg');
    });

    test('무게가 없는 운동은 횟수만 적는다', () {
      expect(setLabel(value: 100, reps: 20), '100kg · 20회');
      expect(setLabel(reps: 12), '12회');
    });
  });

  bumpTests();
}

void bumpTests() {
  group('숫자 밀기', () {
    test('무게 자리는 원판 단위로', () {
      expect(bumpLastNumber('100', 1), '102.5');
      expect(bumpLastNumber('100', -1), '97.5');
      expect(bumpLastNumber('벤치프레스 60', 1), '벤치프레스 62.5');
    });

    test('kg 뒤의 숫자는 횟수라 하나씩', () {
      expect(bumpLastNumber('100kg 20', 1), '100kg 21');
      expect(bumpLastNumber('100kg 20', -1), '100kg 19');
    });

    test('소수는 소수로 남는다', () {
      expect(bumpLastNumber('22.5', 1), '25');
      expect(bumpLastNumber('20', 1), '22.5');
    });

    test('빈 줄에서 올리면 한 단계를 세워 준다', () {
      expect(bumpLastNumber('', 1), '2.5');
      expect(bumpLastNumber('', -1), '');
    });

    test('0 아래로는 내려가지 않고 숫자가 사라진다', () {
      expect(bumpLastNumber('2', -1), '');
      expect(bumpLastNumber('100kg 1', -1), '100kg ');
    });

    test('뒤에 붙은 공백은 지키고 민다', () {
      expect(bumpLastNumber('100kg 20 ', 1), '100kg 21 ');
    });
  });

  group('영어 검색', () {
    test('bench 로 벤치프레스가 먼저 나온다', () {
      expect(suggest('bench', seedNames('ko')).first, '벤치프레스');
    });

    test('표시 이름은 한글 그대로다', () {
      for (final name in suggest('press', seedNames('ko'))) {
        expect(RegExp(r'[a-z]', caseSensitive: false).hasMatch(name), isFalse);
      }
    });

    test('약어와 부분어도 잡는다', () {
      expect(suggest('rdl', seedNames('ko')), contains('루마니안 데드리프트'));
      expect(suggest('ohp', seedNames('ko')), contains('오버헤드프레스'));
      expect(suggest('squat', seedNames('ko')), contains('스쿼트'));
      expect(suggest('curl', seedNames('ko')), contains('바벨컬'));
    });

    test('한글 검색은 그대로 동작한다', () {
      expect(suggest('벤', seedNames('ko')).first, '벤치프레스');
    });
  });

  group('다국어 사전', () {
    test('여덟 언어가 다 채워져 있다', () {
      for (final e in exercises) {
        for (final n in [
          e.ko,
          e.en,
          e.ja,
          e.zhHans,
          e.zhHant,
          e.es,
          e.vi,
          e.th,
        ]) {
          expect(n.trim(), isNotEmpty, reason: '${e.ko} 에 빈 이름');
        }
      }
    });

    test('표시 이름은 화면 언어를 따른다', () {
      expect(seedNames('en').first, 'Bench Press');
      expect(seedNames('ja').first, 'ベンチプレス');
      expect(seedNames('zh_Hant').first, '臥推');
      expect(seedNames('vi').first, 'Đẩy Ngực');
      expect(seedNames('ko').first, '벤치프레스');
    });

    test('어느 언어로 쳐도 화면 언어의 이름이 나온다', () {
      // 영어 화면에서 한글로 치는 트레이너
      expect(suggest('벤치', seedNames('en')).first, 'Bench Press');
      // 한글 화면에서 영어로 치는 회원
      expect(suggest('squat', seedNames('ko')).first, '스쿼트');
      expect(suggest('卧推', seedNames('ko')).first, '벤치프레스');
      expect(suggest('sentadilla', seedNames('ja')).first, 'スクワット');
    });

    test('중국어는 문자 체계를 갈라 본다', () {
      expect(langKeyOf('zh', 'Hant', null), 'zh_Hant');
      expect(langKeyOf('zh', null, 'TW'), 'zh_Hant');
      expect(langKeyOf('zh', null, 'CN'), 'zh_Hans');
      expect(langKeyOf('ja', null, 'JP'), 'ja');
    });

    test('사전에 없는 이름은 친 그대로가 검색 키다', () {
      expect(suggest('벤치 살짝', ['벤치 살짝 기울여서']), ['벤치 살짝 기울여서']);
    });
  });

  group('초성 검색', () {
    test('ㅂㅊㅍㄹㅅ 로 벤치프레스를 찾는다', () {
      expect(chosungOf('벤치프레스'), 'ㅂㅊㅍㄹㅅ');
      expect(suggest('ㅂㅊㅍㄹㅅ', seedNames('ko')), contains('벤치프레스'));
      expect(suggest('ㅅㅋㅌ', seedNames('ko')), contains('스쿼트'));
      expect(suggest('ㄷㄷㄹㅍㅌ', seedNames('ko')), contains('데드리프트'));
    });

    test('앞 몇 글자만 쳐도 잡힌다', () {
      expect(suggest('ㅂㅊ', seedNames('ko')).first, '벤치프레스');
    });

    test('한글 아닌 글자는 그대로 둔다', () {
      expect(chosungOf('T바 로우'), 'Tㅂ ㄹㅇ');
    });
  });

  group('다른 언어 단위', () {
    test('세트 단위를 언어별로 읽는다', () {
      expect(parseSetLine('100kg 10회 3세트')!.count, 3);
      expect(parseSetLine('100kg 10回 3セット')!.count, 3);
      expect(parseSetLine('100kg 10次 3组')!.count, 3);
      expect(parseSetLine('100kg 10 lần 3 hiệp')!.count, 3);
    });

    test('lbs 를 쳐도 파운드 그대로다', () {
      final p = parseSetLine('225lbs 5reps')!;
      expect(p.value, 225);
      expect(p.unit, 'lb');
      expect(p.reps, 5);
    });
  });
}
