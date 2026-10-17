import 'package:flutter_test/flutter_test.dart';
import 'package:setpad/parser.dart';
import 'package:setpad/record_query.dart';
import 'package:setpad/workout_timing.dart';

void main() {
  test("수 없는 'bpm' 은 옛 제목 그대로 120 이고, 새로 만드는 자리만 60 을 적는다", () {
    expect(TimingSpec.parse('메트로놈 bpm')!.bpm, 120);
    expect(TimingSpec.parse('bpm 푸시업 1칸 100개 채우기')!.bpm, 120);
    expect(TimingSpec.newBpm, 60);
    expect(
      const TimingSpec(bpm: TimingSpec.newBpm).applyTo('푸시업'),
      '푸시업 60bpm',
    );
  });

  test('3x10 은 세트 표기라 라운드가 아니다', () {
    for (final name in ['푸시업 3x10 타바타', '푸시업 3 x 10 타바타', '타바타 스쿼트 3×10']) {
      expect(TimingSpec.parse(name)!.rounds, 8, reason: name);
    }
    expect(TimingSpec.parse('타바타 x6')!.rounds, 6);
    expect(TimingSpec.parse('타바타 × 6')!.rounds, 6);
    expect(TimingSpec.parse('버피 타바타 20/10 x6')!.rounds, 6);
    expect(TimingSpec.parse('tabata 30/15 x6 100bpm')!.rounds, 6);
    expect(TimingSpec.parse('버피 60 bpm x8')!.bpm, 60);
    expect(TimingSpec.parse('타바타 30초/15초 6라운드')!.rounds, 6);
    // The same pattern feeds the parser's timer tokens.
    expect('푸시업 3x10 타바타'.replaceAll(timerTokens, '#'), '푸시업 3x10 타바타');
    expect('타바타 x6'.replaceAll(timerTokens, '#'), '타바타 #');
  });

  test('applyTo 는 세트 표기를 건드리지 않고, 고친 제목은 같은 설정으로 다시 읽힌다', () {
    final spec = TimingSpec.parse(
      '푸시업 3x10 타바타',
    )!.copyWith(rounds: 6, work: 30);
    final name = spec.applyTo('푸시업 3x10 타바타');
    expect(name, startsWith('푸시업 3x10 타바타'));
    expect(TimingSpec.parse(name), spec);

    const specs = [
      TimingSpec(tabata: true),
      TimingSpec(tabata: true, rounds: 6),
      TimingSpec(tabata: true, work: 45, rest: 15, rounds: 12),
      TimingSpec(bpm: 60),
      TimingSpec(bpm: 90),
      TimingSpec(tabata: true, bpm: 100, work: 30, rest: 15, rounds: 4),
    ];
    const names = [
      '',
      '버피',
      '푸시업 3x10',
      '스쿼트 3 x 10',
      '버피 타바타',
      '버피 타바타 30/15 x6 100bpm',
      '타바타 버피 3',
      '케틀벨 16',
      '버피 bpm',
      'bpm 3세트',
      '타바타 30초/15초 6라운드',
    ];
    for (final n in names) {
      for (final s in specs) {
        final base = TimingSpec.removeFrom(n);
        final out = s.applyTo(base, tabataWord: '타바타');
        expect(TimingSpec.parse(out), s, reason: '"$n" → "$out"');
        if (n.contains('3x10')) expect(out, contains('3x10'));
        if (n.contains('3 x 10')) expect(out, contains('3 x 10'));
      }
    }
    // A bare number at the end would turn " x6" into set notation.
    expect(
      const TimingSpec(tabata: true, rounds: 6).applyTo('타바타 버피 3'),
      '타바타 버피 3 ·x6',
    );
    // In place: only the number changes.
    expect(
      const TimingSpec(tabata: true, rounds: 10).applyTo('타바타 x 6'),
      '타바타 x 10',
    );
    expect(
      const TimingSpec(tabata: true, rounds: 4).applyTo('타바타 6라운드'),
      '타바타 4라운드',
    );
    expect(const TimingSpec(tabata: true).applyTo(''), 'Tabata');
  });

  test("타바타 제목의 'bpm 100 x6' 은 6라운드다 — 옛 앱이 그렇게 적었다", () {
    for (final name in ['버피 타바타 bpm 100 x6', '버피 bpm:100 x6 타바타']) {
      expect(TimingSpec.parse(name)!.rounds, 6, reason: name);
      expect(TimingSpec.parse(name)!.bpm, 100, reason: name);
      expect(statName(name), '버피', reason: name);
    }
    const name = '버피 타바타 bpm 100 x6';
    expect(
      TimingSpec.parse(name)!.copyWith(rounds: 4).applyTo(name),
      '버피 타바타 bpm 100 x4',
    );
    // Without a tabata word it is a tempo and three sets ([tempoPattern]):
    // the x is not a timer token there.
    expect('스쿼트 bpm 30 x3'.replaceAll(timerTokens, '#'), '스쿼트 # x3');
    expect(TimingSpec.parse('스쿼트 bpm 30 x3'), const TimingSpec(bpm: 30));
    expect(statName('스쿼트 bpm 30 x3'), '스쿼트 x3');
  });

  test('간격이나 맨 수 뒤의 3x10 도 세트 표기다', () {
    for (final name in ['버피 타바타 30/15 3x10', '스쿼트 100 3x10 타바타']) {
      final spec = TimingSpec.parse(name)!;
      expect(spec.rounds, 8, reason: name);
      final out = spec.copyWith(rounds: 6).applyTo(name);
      expect(out, contains('3x10'), reason: out);
      expect(TimingSpec.parse(out), spec.copyWith(rounds: 6), reason: out);
    }
    expect(TimingSpec.removeFrom('스쿼트 100 3x10 타바타'), '스쿼트 100 3x10');
    // Right after an interval an x is still rounds.
    expect(TimingSpec.parse('타바타 20/10x6')!.rounds, 6);
  });

  test("removeFrom 은 applyTo 가 붙인 '·x6' 을 점째 떼고, 사람이 쓴 '·' 는 둔다", () {
    const spec = TimingSpec(tabata: true, rounds: 6);
    final name = spec.applyTo('타바타 버피 3');
    expect(name, '타바타 버피 3 ·x6');
    expect(TimingSpec.removeFrom(name), '버피 3');
    expect(statName(name), '버피 3');
    expect(
      spec.applyTo(TimingSpec.removeFrom(name), tabataWord: '타바타'),
      '버피 3 타바타 x6',
    );
    expect(TimingSpec.removeFrom('버피 · 점프 타바타'), '버피 · 점프');
  });

  test(
    'applyTo 왕복은 다른 종류의 타이머 낱말이 없는 이름에서 지켜지고, 종류를 바꿀 때는 removeFrom 을 거친다',
    () {
      for (final (spec, name) in [
        (const TimingSpec(tabata: true, rounds: 6), '버피 타바타 20/10 x8'),
        (const TimingSpec(tabata: true, work: 30, rest: 15), '타바타 버피 3'),
        (const TimingSpec(bpm: 90), '푸시업 60bpm'),
        (const TimingSpec(bpm: 90), '스쿼트 3x10'),
        (
          const TimingSpec(tabata: true, bpm: 100, rounds: 4),
          '버피 타바타 bpm 120 x6',
        ),
      ]) {
        final out = spec.applyTo(name);
        expect(TimingSpec.parse(out), spec, reason: '"$name" → "$out"');
      }
      // Another kind's word stays in the name.
      const tabata = TimingSpec(tabata: true, rounds: 6);
      expect(TimingSpec.parse(tabata.applyTo('스쿼트 bpm'))!.bpm, 120);
      expect(
        TimingSpec.parse(tabata.applyTo(TimingSpec.removeFrom('스쿼트 bpm'))),
        tabata,
      );
    },
  );

  test('removeFrom 은 타이머만 떼고, 남는 것이 없으면 빈 글이다', () {
    expect(TimingSpec.removeFrom('타바타'), '');
    expect(TimingSpec.removeFrom('60bpm'), '');
    expect(TimingSpec.removeFrom('버피 타바타 30/15 x6 100bpm'), '버피');
    expect(TimingSpec.removeFrom('푸시업 3x10 타바타'), '푸시업 3x10');
    // Not a timer: left alone, even its slashes.
    expect(TimingSpec.removeFrom(' 스쿼트 5/3/1 '), '스쿼트 5/3/1');
  });

  test('statName 은 removeFrom 을 부르고, 빈 결과면 원제목이다', () {
    expect(statName('타바타'), '타바타');
    expect(statName('푸시업 60bpm'), '푸시업');
    expect(statName('버피 타바타 30/15 10라운드'), '버피');
    expect(statName('푸시업 3x10 타바타'), '푸시업 3x10');
    expect(statName(' 벤치프레스 80kg '), '벤치프레스 80kg');
  });

  test('tail 은 길이와 같음에만 있고 제목에는 없다', () {
    const plain = TimingSpec(tabata: true),
        tail = TimingSpec(tabata: true, tail: true);
    expect(plain.duration, 3 + 20 * 8 + 10 * 7);
    expect(tail.duration, plain.duration + 10);
    expect(plain == tail, isFalse);
    expect(plain.hashCode == tail.hashCode, isFalse);
    expect(plain.copyWith(tail: true), tail);
    expect(tail.copyWith(rounds: 6).tail, isTrue);
    expect(tail.applyTo('버피 타바타'), plain.applyTo('버피 타바타'));
    expect(TimingSpec.parse(tail.applyTo('버피 타바타'))!.tail, isFalse);
  });
}
