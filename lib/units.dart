/// 운동 기록에 쓰는 단위.
///
/// 예전에는 무게를 kg 하나로만 들고 있었고, 'lb' 로 쳐도 kg 로 바꿔 저장했다.
/// 파운드로 운동하는 사람에게는 자기가 친 숫자가 사라지는 셈이라 못 쓴다.
/// 친 단위를 그대로 남기고 그대로 보여준다 — 환산은 사람이 원할 때 할 일이지
/// 앱이 몰래 할 일이 아니다.
library;

enum UnitKind { weight, distance, duration }

class Unit {
  const Unit(this.id, this.label, this.kind, this.step, this.steps);

  /// 저장에 쓰는 값. 바뀌면 예전 기록을 못 읽으므로 고정이다.
  final String id;

  /// 화면에 붙는 글자. 'kg', 'lb', 'km'…
  final String label;
  final UnitKind kind;

  /// +/- 한 번에 움직이는 기본 폭.
  final double step;

  /// 길게 눌러 고를 수 있는 폭들. 원판이 나라마다 다르고, 사람마다
  /// 올리는 단위가 다르다.
  final List<double> steps;
}

const units = <Unit>[
  // 무게 — 2.5kg 은 국내 원판 한 쌍, 5lb 는 파운드 원판 한 쌍이다.
  Unit('kg', 'kg', UnitKind.weight, 2.5, [1, 1.25, 2.5, 5, 10, 20]),
  Unit('lb', 'lb', UnitKind.weight, 5, [1, 2.5, 5, 10, 25, 45]),
  // 거리 — 유산소와 캐리 종목.
  Unit('km', 'km', UnitKind.distance, 0.5, [0.1, 0.5, 1, 5]),
  Unit('m', 'm', UnitKind.distance, 50, [5, 10, 50, 100, 400]),
  Unit('mi', 'mi', UnitKind.distance, 0.5, [0.1, 0.25, 0.5, 1]),
  // 시간 — 플랭크·행잉·인터벌. 초 단위로 들고 있고 표시만 바꾼다.
  Unit('s', '초', UnitKind.duration, 10, [1, 5, 10, 15, 30, 60]),
  Unit('min', '분', UnitKind.duration, 1, [0.5, 1, 5, 10]),
];

final unitById = {for (final u in units) u.id: u};

const defaultUnit = 'kg';

/// 친 글자 → 단위. 여덟 언어의 표기를 다 받는다.
const _aliases = <String, String>{
  'kg': 'kg',
  '킬로': 'kg',
  '키로': 'kg', // 입말 표기. "80키로"
  'kilo': 'kg',
  'kilos': 'kg',
  'キロ': 'kg',
  '公斤': 'kg',
  '千克': 'kg',
  'kilogramo': 'kg',
  'kilogramos': 'kg',
  'lb': 'lb',
  'lbs': 'lb',
  '파운드': 'lb',
  'pound': 'lb',
  'pounds': 'lb',
  'ポンド': 'lb',
  '磅': 'lb',
  'libra': 'lb',
  'libras': 'lb',
  'km': 'km',
  '킬로미터': 'km',
  '公里': 'km',
  'キロメートル': 'km',
  'm': 'm',
  '미터': 'm',
  '米': 'm',
  'メートル': 'm',
  'metro': 'm',
  'metros': 'm',
  'mi': 'mi',
  'mile': 'mi',
  'miles': 'mi',
  '마일': 'mi',
  '英里': 'mi',
  's': 's',
  'sec': 's',
  'secs': 's',
  'second': 's',
  'seconds': 's',
  '초': 's',
  '秒': 's',
  'segundo': 's',
  'segundos': 's',
  'giây': 's',
  'วินาที': 's',
  'min': 'min',
  'mins': 'min',
  'minute': 'min',
  'minutes': 'min',
  '분': 'min',
  '分': 'min',
  'minuto': 'min',
  'minutos': 'min',
  'phút': 'min',
  'นาที': 'min',
};

/// 파서가 쓰는 정규식 조각. 긴 것부터 놓아야 'm' 이 'min' 을 잘라먹지 않는다.
final unitPattern =
    (_aliases.keys.toList()..sort((a, b) => b.length.compareTo(a.length)))
        .map(RegExp.escape)
        .join('|');

String? unitOf(String token) => _aliases[token.toLowerCase()];

/// 소수점이 필요 없으면 뗀다. 100.0kg 을 그렇게 읽는 사람은 없다.
String formatNumber(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toString();

/// "100kg", "45lb", "30초"
String formatValue(double value, String unitId) {
  final u = unitById[unitId] ?? unitById[defaultUnit]!;
  return '${formatNumber(value)}${u.label}';
}
