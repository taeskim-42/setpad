import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/parser.dart';

void main() {
  group('세트 줄 읽기', () {
    test('단위를 붙였든 안 붙였든 읽는다', () {
      expect(parseSetLine('100kg 20회'), const ParsedSet(kg: 100, reps: 20));
      expect(parseSetLine('100 20'), const ParsedSet(kg: 100, reps: 20));
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

    test('세트 수는 20을 넘지 않는다', () {
      expect(parseSetLine('60kg 10회 x99')?.count, 20);
    });

    test('숫자를 다 먹고 남은 것이 메모다', () {
      final parsed = parseSetLine('100kg 20회 마지막에 힘들었음');
      expect(parsed?.kg, 100);
      expect(parsed?.reps, 20);
      expect(parsed?.note, '마지막에 힘들었음');
      expect(parseSetLine('20회 어깨 불편')?.note, '어깨 불편');
    });

    test('파운드는 kg으로 바꿔 적는다', () {
      expect(parseSetLine('225lb 5회')?.kg, 102.1);
    });

    test('숫자가 없으면 세트가 아니다', () {
      expect(parseSetLine('그냥 메모'), isNull);
      expect(parseSetLine('   '), isNull);
    });

    test('소수 무게도 읽는다', () {
      expect(parseSetLine('22.5kg 12회')?.kg, 22.5);
    });
  });

  group('자동완성', () {
    const pool = ['벤치프레스', '인클라인 벤치프레스', '덤벨 프레스', '레그프레스'];

    test('앞글자 일치가 먼저다', () {
      expect(suggest('벤', pool), ['벤치프레스', '인클라인 벤치프레스']);
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
      expect(formatKg(100), '100kg');
      expect(formatKg(22.5), '22.5kg');
    });

    test('무게가 없는 운동은 횟수만 적는다', () {
      expect(setLabel(kg: 100, reps: 20), '100kg · 20회');
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
      expect(suggest('bench', seedExercises).first, '벤치프레스');
    });

    test('표시 이름은 한글 그대로다', () {
      for (final name in suggest('press', seedExercises)) {
        expect(RegExp(r'[a-z]', caseSensitive: false).hasMatch(name), isFalse);
      }
    });

    test('약어와 부분어도 잡는다', () {
      expect(suggest('rdl', seedExercises), contains('루마니안 데드리프트'));
      expect(suggest('ohp', seedExercises), contains('오버헤드프레스'));
      expect(suggest('squat', seedExercises), contains('스쿼트'));
      expect(suggest('curl', seedExercises), contains('바벨컬'));
    });

    test('한글 검색은 그대로 동작한다', () {
      expect(suggest('벤', seedExercises).first, '벤치프레스');
    });
  });
}
