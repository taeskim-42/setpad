/// 운동 이름 사전. UI 문구(arb)와 떼어 둔 이유는 성격이 다르기 때문이다 —
/// 이건 **번역문이 아니라 데이터**다. 한 운동이 언어마다 다른 이름을 갖되
/// 같은 한 줄에 머물러야, "영어로 치고 한글로 보는" 게 가능해진다.
///
/// 표시 이름은 기기 언어를 따르고, **검색은 여덟 언어를 전부 받는다.**
/// 한국인 트레이너가 'bench' 로 찾든 외국인 회원이 '벤치' 로 찾든 같은
/// 운동에 닿는다. 초성(ㅂㅊㅍㄹㅅ)도 검색 키다.
///
/// 마스터 테이블이 아니다. 실제 어휘는 사용자가 친 이름에서 자란다.
library;

class Exercise {
  const Exercise(
    this.ko,
    this.en,
    this.ja,
    this.zhHans,
    this.zhHant,
    this.es,
    this.vi,
    this.th, [
    this.alias = '',
  ]);

  final String ko, en, ja, zhHans, zhHant, es, vi, th;

  /// 어느 이름에도 안 들어가는 약어·별칭. 'rdl', 'ohp', '턱걸이' 같은 것.
  final String alias;

  String name(String lang) => switch (lang) {
    'en' => en,
    'ja' => ja,
    'zh_Hans' => zhHans,
    'zh_Hant' => zhHant,
    'es' => es,
    'vi' => vi,
    'th' => th,
    _ => ko,
  };

  /// 검색이 훑는 전부.
  List<String> get keys => [
    ko,
    en,
    ja,
    zhHans,
    zhHant,
    es,
    vi,
    th,
    alias,
    chosungOf(ko),
  ].where((s) => s.isNotEmpty).map((s) => s.toLowerCase()).toList();
}

/// 기기 로케일 → 이 사전의 언어 키. 중국어만 문자 체계를 갈라 본다.
String langKeyOf(String languageCode, String? scriptCode, String? countryCode) {
  if (languageCode != 'zh') return languageCode;
  final hant =
      scriptCode == 'Hant' ||
      const ['TW', 'HK', 'MO'].contains(countryCode ?? '');
  return hant ? 'zh_Hant' : 'zh_Hans';
}

const _cho = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

/// "벤치프레스" → "ㅂㅊㅍㄹㅅ". 한글이 아닌 글자는 그대로 둔다.
String chosungOf(String text) => String.fromCharCodes(
  text.runes.expand((r) {
    if (r < 0xAC00 || r > 0xD7A3) return [r];
    return _cho[(r - 0xAC00) ~/ 28 ~/ 21].runes;
  }),
);

const _jung = [
  'ㅏ',
  'ㅐ',
  'ㅑ',
  'ㅒ',
  'ㅓ',
  'ㅔ',
  'ㅕ',
  'ㅖ',
  'ㅗ',
  'ㅘ',
  'ㅙ',
  'ㅚ',
  'ㅛ',
  'ㅜ',
  'ㅝ',
  'ㅞ',
  'ㅟ',
  'ㅠ',
  'ㅡ',
  'ㅢ',
  'ㅣ',
];
const _jong = [
  '',
  'ㄱ',
  'ㄲ',
  'ㄳ',
  'ㄴ',
  'ㄵ',
  'ㄶ',
  'ㄷ',
  'ㄹ',
  'ㄺ',
  'ㄻ',
  'ㄼ',
  'ㄽ',
  'ㄾ',
  'ㄿ',
  'ㅀ',
  'ㅁ',
  'ㅂ',
  'ㅄ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

/// 한글을 자모로 푼다. 벤 → ㅂㅔㄴ. 한글이 아니면 그대로 둔다.
///
/// **왜 자모로 재는가.** 오타를 음절 단위로 세면 '밴치프레스'는 다섯 자 중
/// 한 자가 틀린 것(20%)이지만, 실제로 틀린 건 ㅔ/ㅐ 하나다 — 자모로는 열한
/// 개 중 하나(9%)다. 음절로 세면 한글에만 유독 가혹해서, 오타를 봐주려고
/// 한도를 올리면 이번엔 영어에서 엉뚱한 것이 걸린다. 자모로 재면 언어마다
/// 다른 한도를 둘 이유가 없어진다.
String jamoOf(String text) {
  final out = StringBuffer();
  for (final r in text.runes) {
    if (r < 0xAC00 || r > 0xD7A3) {
      out.writeCharCode(r);
      continue;
    }
    final code = r - 0xAC00;
    out.write(_cho[code ~/ 588]);
    out.write(_jung[(code % 588) ~/ 28]);
    out.write(_jong[code % 28]);
  }
  return out.toString();
}

/// ko, en, ja, 简体, 繁體, es, vi, th, [별칭]
const exercises = <Exercise>[
  // 가슴
  Exercise(
    '벤치프레스',
    'Bench Press',
    'ベンチプレス',
    '卧推',
    '臥推',
    'Press de Banca',
    'Đẩy Ngực',
    'เบนช์เพรส',
    'bp',
  ),
  Exercise(
    '인클라인 벤치프레스',
    'Incline Bench Press',
    'インクラインベンチプレス',
    '上斜卧推',
    '上斜臥推',
    'Press Inclinado',
    'Đẩy Ngực Dốc Lên',
    'เบนช์เพรสเอียงขึ้น',
  ),
  Exercise(
    '디클라인 벤치프레스',
    'Decline Bench Press',
    'デクラインベンチプレス',
    '下斜卧推',
    '下斜臥推',
    'Press Declinado',
    'Đẩy Ngực Dốc Xuống',
    'เบนช์เพรสเอียงลง',
  ),
  Exercise(
    '덤벨 프레스',
    'Dumbbell Press',
    'ダンベルプレス',
    '哑铃卧推',
    '啞鈴臥推',
    'Press con Mancuernas',
    'Đẩy Tạ Đơn',
    'ดัมเบลเพรส',
    'db press',
  ),
  Exercise(
    '인클라인 덤벨 프레스',
    'Incline Dumbbell Press',
    'インクラインダンベルプレス',
    '上斜哑铃卧推',
    '上斜啞鈴臥推',
    'Press Inclinado con Mancuernas',
    'Đẩy Tạ Đơn Dốc Lên',
    'ดัมเบลเพรสเอียงขึ้น',
  ),
  Exercise(
    '체스트 프레스',
    'Chest Press',
    'チェストプレス',
    '坐姿推胸',
    '坐姿推胸',
    'Press de Pecho',
    'Đẩy Ngực Máy',
    'เชสต์เพรส',
  ),
  Exercise(
    '펙덱 플라이',
    'Pec Deck Fly',
    'ペックデックフライ',
    '蝴蝶机夹胸',
    '蝴蝶機夾胸',
    'Contractora',
    'Ép Ngực Máy',
    'เพคเด็คฟลาย',
  ),
  Exercise(
    '케이블 크로스오버',
    'Cable Crossover',
    'ケーブルクロスオーバー',
    '绳索夹胸',
    '繩索夾胸',
    'Cruce de Poleas',
    'Kéo Cáp Chéo',
    'เคเบิลครอสโอเวอร์',
  ),
  Exercise(
    '푸시업',
    'Push Up',
    'プッシュアップ',
    '俯卧撑',
    '伏地挺身',
    'Flexiones',
    'Hít Đất',
    'วิดพื้น',
    'pushup',
  ),
  // 등
  Exercise(
    '데드리프트',
    'Deadlift',
    'デッドリフト',
    '硬拉',
    '硬舉',
    'Peso Muerto',
    'Nâng Tạ Đất',
    'เดดลิฟต์',
    'dl dead lift',
  ),
  Exercise(
    '루마니안 데드리프트',
    'Romanian Deadlift',
    'ルーマニアンデッドリフト',
    '罗马尼亚硬拉',
    '羅馬尼亞硬舉',
    'Peso Muerto Rumano',
    'Nâng Tạ Kiểu Romania',
    'โรมาเนียนเดดลิฟต์',
    'rdl',
  ),
  Exercise(
    '랫풀다운',
    'Lat Pulldown',
    'ラットプルダウン',
    '高位下拉',
    '滑輪下拉',
    'Jalón al Pecho',
    'Kéo Xô',
    'แลทพูลดาวน์',
    'pull down',
  ),
  Exercise(
    '풀업',
    'Pull Up',
    'プルアップ',
    '引体向上',
    '引體向上',
    'Dominadas',
    'Hít Xà',
    'พูลอัพ',
    '턱걸이 pullup',
  ),
  Exercise(
    '친업',
    'Chin Up',
    'チンニング',
    '反握引体向上',
    '反握引體向上',
    'Dominadas Supinas',
    'Hít Xà Ngửa',
    'ชินอัพ',
    'chinup',
  ),
  Exercise(
    '바벨로우',
    'Barbell Row',
    'ベントオーバーロー',
    '杠铃划船',
    '槓鈴划船',
    'Remo con Barra',
    'Chèo Tạ Đòn',
    'บาร์เบลโรว์',
  ),
  Exercise(
    '덤벨로우',
    'Dumbbell Row',
    'ワンハンドローイング',
    '哑铃划船',
    '啞鈴划船',
    'Remo con Mancuerna',
    'Chèo Tạ Đơn',
    'ดัมเบลโรว์',
    'db row',
  ),
  Exercise(
    '시티드 로우',
    'Seated Row',
    'シーテッドロー',
    '坐姿划船',
    '坐姿划船',
    'Remo Sentado',
    'Chèo Ngồi',
    'ซีทเต็ดโรว์',
  ),
  Exercise(
    '케이블 로우',
    'Cable Row',
    'ケーブルロー',
    '绳索划船',
    '繩索划船',
    'Remo en Polea',
    'Chèo Cáp',
    'เคเบิลโรว์',
  ),
  Exercise(
    '티바로우',
    'T-Bar Row',
    'Tバーロー',
    'T杠划船',
    'T槓划船',
    'Remo en T',
    'Chèo T-Bar',
    'ทีบาร์โรว์',
    'tbar',
  ),
  // 하체
  Exercise(
    '스쿼트',
    'Squat',
    'スクワット',
    '深蹲',
    '深蹲',
    'Sentadilla',
    'Squat',
    'สควอท',
    // 백스쿼트·바벨 스쿼트는 스쿼트다. 이름 열쇠는 오타 거리로 잇지 않으니
    // (핵스쿼트와 자모 하나 차이) 별칭으로 둔다.
    '스쾃 백스쿼트 바벨스쿼트 backsquat barbellsquat',
  ),
  Exercise(
    '프론트 스쿼트',
    'Front Squat',
    'フロントスクワット',
    '前蹲',
    '前蹲',
    'Sentadilla Frontal',
    'Squat Trước',
    'ฟรอนต์สควอท',
  ),
  Exercise(
    '핵스쿼트',
    'Hack Squat',
    'ハックスクワット',
    '哈克深蹲',
    '哈克深蹲',
    'Hack Squat',
    'Hack Squat',
    'แฮ็คสควอท',
  ),
  Exercise(
    '레그프레스',
    'Leg Press',
    'レッグプレス',
    '腿举',
    '腿推',
    'Prensa de Piernas',
    'Đạp Đùi',
    'เลกเพรส',
  ),
  Exercise(
    '레그익스텐션',
    'Leg Extension',
    'レッグエクステンション',
    '腿屈伸',
    '腿伸展',
    'Extensión de Piernas',
    'Duỗi Chân',
    'เลกเอ็กซ์เทนชัน',
  ),
  Exercise(
    '레그컬',
    'Leg Curl',
    'レッグカール',
    '腿弯举',
    '腿彎舉',
    'Curl Femoral',
    'Cuốn Chân',
    'เลกเคิร์ล',
  ),
  Exercise(
    '런지',
    'Lunge',
    'ランジ',
    '弓步蹲',
    '弓步蹲',
    'Zancadas',
    'Chùng Chân',
    'ลันจ์',
  ),
  Exercise(
    '불가리안 스플릿 스쿼트',
    'Bulgarian Split Squat',
    'ブルガリアンスクワット',
    '保加利亚分腿蹲',
    '保加利亞分腿蹲',
    'Sentadilla Búlgara',
    'Squat Bulgaria',
    'บัลแกเรียนสปลิทสควอท',
  ),
  Exercise(
    '힙쓰러스트',
    'Hip Thrust',
    'ヒップスラスト',
    '臀推',
    '臀推',
    'Empuje de Cadera',
    'Đẩy Hông',
    'ฮิปทรัสต์',
  ),
  Exercise(
    '카프레이즈',
    'Calf Raise',
    'カーフレイズ',
    '提踵',
    '提踵',
    'Elevación de Talones',
    'Nhón Bắp Chân',
    'คาล์ฟเรส',
  ),
  Exercise(
    '레그레이즈',
    'Leg Raise',
    'レッグレイズ',
    '举腿',
    '舉腿',
    'Elevación de Piernas',
    'Nâng Chân',
    'เลกเรส',
  ),
  // 어깨
  Exercise(
    '오버헤드프레스',
    'Overhead Press',
    'オーバーヘッドプレス',
    '站姿推举',
    '站姿推舉',
    'Press Militar',
    'Đẩy Vai Qua Đầu',
    'โอเวอร์เฮดเพรส',
    'ohp',
  ),
  Exercise(
    '숄더프레스',
    'Shoulder Press',
    'ショルダープレス',
    '肩推',
    '肩推',
    'Press de Hombro',
    'Đẩy Vai',
    'โชลเดอร์เพรส',
  ),
  Exercise(
    '덤벨 숄더프레스',
    'Dumbbell Shoulder Press',
    'ダンベルショルダープレス',
    '哑铃肩推',
    '啞鈴肩推',
    'Press de Hombro con Mancuernas',
    'Đẩy Vai Tạ Đơn',
    'ดัมเบลโชลเดอร์เพรส',
  ),
  Exercise(
    '사이드 레터럴 레이즈',
    'Lateral Raise',
    'サイドレイズ',
    '侧平举',
    '側平舉',
    'Elevación Lateral',
    'Nâng Tạ Ngang Vai',
    'ไซด์เรส',
    'side lateral',
  ),
  Exercise(
    '프론트 레이즈',
    'Front Raise',
    'フロントレイズ',
    '前平举',
    '前平舉',
    'Elevación Frontal',
    'Nâng Tạ Trước',
    'ฟรอนต์เรส',
  ),
  Exercise(
    '벤트오버 레터럴 레이즈',
    'Bent Over Lateral Raise',
    'リアレイズ',
    '俯身侧平举',
    '俯身側平舉',
    'Elevación Posterior',
    'Nâng Tạ Ngang Cúi Người',
    'เบนท์โอเวอร์เรส',
    'rear delt',
  ),
  Exercise(
    '업라이트 로우',
    'Upright Row',
    'アップライトロー',
    '直立划船',
    '直立划船',
    'Remo al Mentón',
    'Chèo Đứng',
    'อัพไรท์โรว์',
  ),
  Exercise(
    '슈러그',
    'Shrug',
    'シュラッグ',
    '耸肩',
    '聳肩',
    'Encogimientos',
    'Nhún Vai',
    'ชรัก',
  ),
  // 팔
  Exercise(
    '바벨컬',
    'Barbell Curl',
    'バーベルカール',
    '杠铃弯举',
    '槓鈴彎舉',
    'Curl con Barra',
    'Cuốn Tạ Đòn',
    'บาร์เบลเคิร์ล',
  ),
  Exercise(
    '덤벨컬',
    'Dumbbell Curl',
    'ダンベルカール',
    '哑铃弯举',
    '啞鈴彎舉',
    'Curl con Mancuernas',
    'Cuốn Tạ Đơn',
    'ดัมเบลเคิร์ล',
    'db curl',
  ),
  Exercise(
    '해머컬',
    'Hammer Curl',
    'ハンマーカール',
    '锤式弯举',
    '錘式彎舉',
    'Curl Martillo',
    'Cuốn Tạ Búa',
    'แฮมเมอร์เคิร์ล',
  ),
  Exercise(
    '프리처컬',
    'Preacher Curl',
    'プリーチャーカール',
    '牧师凳弯举',
    '牧師椅彎舉',
    'Curl Predicador',
    'Cuốn Tạ Ghế Dốc',
    'พรีชเชอร์เคิร์ล',
  ),
  Exercise(
    '케이블컬',
    'Cable Curl',
    'ケーブルカール',
    '绳索弯举',
    '繩索彎舉',
    'Curl en Polea',
    'Cuốn Tạ Cáp',
    'เคเบิลเคิร์ล',
  ),
  Exercise(
    '트라이셉스 익스텐션',
    'Triceps Extension',
    'トライセプスエクステンション',
    '三头肌伸展',
    '三頭肌伸展',
    'Extensión de Tríceps',
    'Duỗi Tay Sau',
    'ไตรเซปส์เอ็กซ์เทนชัน',
    'tricep',
  ),
  Exercise(
    '케이블 푸시다운',
    'Cable Pushdown',
    'プレスダウン',
    '绳索下压',
    '繩索下壓',
    'Extensión en Polea',
    'Đẩy Cáp Xuống',
    'เคเบิลพุชดาวน์',
    'push down',
  ),
  Exercise(
    '딥스',
    'Dips',
    'ディップス',
    '双杠臂屈伸',
    '雙槓臂屈伸',
    'Fondos',
    'Hít Xà Kép',
    'ดิพส์',
    'dip',
  ),
  Exercise(
    '킥백',
    'Kickback',
    'キックバック',
    '臂屈伸后踢',
    '臂屈伸後踢',
    'Patada de Tríceps',
    'Đá Tay Sau',
    'คิกแบ็ก',
    'kick back',
  ),
  // 코어·유산소
  Exercise('플랭크', 'Plank', 'プランク', '平板支撑', '棒式', 'Plancha', 'Plank', 'แพลงก์'),
  Exercise(
    '사이드 플랭크',
    'Side Plank',
    'サイドプランク',
    '侧平板支撑',
    '側棒式',
    'Plancha Lateral',
    'Plank Nghiêng',
    'ไซด์แพลงก์',
  ),
  Exercise(
    '크런치',
    'Crunch',
    'クランチ',
    '卷腹',
    '捲腹',
    'Abdominales',
    'Gập Bụng',
    'ครันช์',
  ),
  Exercise(
    '싯업',
    'Sit Up',
    'シットアップ',
    '仰卧起坐',
    '仰臥起坐',
    'Abdominales Completos',
    'Gập Bụng Toàn Phần',
    'ซิทอัพ',
    'situp',
  ),
  Exercise(
    '행잉 레그레이즈',
    'Hanging Leg Raise',
    'ハンギングレッグレイズ',
    '悬垂举腿',
    '懸垂舉腿',
    'Elevación de Piernas Colgado',
    'Nâng Chân Treo Xà',
    'แฮงกิงเลกเรส',
  ),
  Exercise(
    '러시안 트위스트',
    'Russian Twist',
    'ロシアンツイスト',
    '俄罗斯转体',
    '俄羅斯轉體',
    'Giro Ruso',
    'Xoay Người Nga',
    'รัสเซียนทวิสต์',
  ),
  Exercise(
    '러닝',
    'Running',
    'ランニング',
    '跑步',
    '跑步',
    'Correr',
    'Chạy Bộ',
    'วิ่ง',
    'run treadmill',
  ),
  Exercise(
    '사이클',
    'Cycling',
    'サイクリング',
    '骑行',
    '騎行',
    'Bicicleta',
    'Đạp Xe',
    'ปั่นจักรยาน',
    'bike',
  ),
  Exercise(
    '로잉',
    'Rowing',
    'ローイング',
    '划船机',
    '划船機',
    'Remo',
    'Chèo Thuyền',
    'โรว์อิ้ง',
  ),
  Exercise(
    '버피',
    'Burpee',
    'バーピー',
    '波比跳',
    '波比跳',
    'Burpees',
    'Burpee',
    'เบอร์ปี้',
  ),
  Exercise(
    '점핑잭',
    'Jumping Jack',
    'ジャンピングジャック',
    '开合跳',
    '開合跳',
    'Saltos de Tijera',
    'Nhảy Dang Tay Chân',
    'จัมปิ้งแจ็ค',
  ),
  // 음식 표에 같은 이름의 제품이 있는 운동(2026-09-23 운영 표 실측: 굿모닝·클린).
  // 사전에 있어야 입력 줄이 끼니로 가르지 않는다. '클린' 만 친 줄은 사전 별칭이 아니라
  // 운동 낱말(parser.dart _exerciseWords)로 잡는다 — 별칭이면 기록 검색이 '클린' 을
  // 파워클린으로 바꾼다.
  Exercise(
    '굿모닝',
    'Good Morning',
    'グッドモーニング',
    '早安式体前屈',
    '早安式體前屈',
    'Buenos Días',
    'Good Morning',
    'กู๊ดมอร์นิ่ง',
  ),
  Exercise(
    '파워클린',
    'Power Clean',
    'パワークリーン',
    '高翻',
    '高翻',
    'Cargada de Potencia',
    'Power Clean',
    'พาวเวอร์คลีน',
  ),
];

/// 어느 언어의 이름으로든 그 운동을 되찾는다. 사용자가 영어 화면에서 담은
/// 'Bench Press' 도, 한글 화면의 '벤치프레스' 도 같은 한 줄을 가리킨다.
final Map<String, Exercise> exerciseByName = {
  for (final e in exercises)
    for (final n in [e.ko, e.en, e.ja, e.zhHans, e.zhHant, e.es, e.vi, e.th])
      n.toLowerCase(): e,
};

List<String> seedNames(String lang) => [
  for (final e in exercises) e.name(lang),
];

/// 사전 운동의 부위(한국어 이름 → 부위). 기록 검색의 `part` 가 이 표로 푼다.
///
/// 사전 구간 주석을 따르되 두 곳을 고쳤다: 코어·유산소 구간은 core 와 cardio 로
/// 가르고, 하체 구간의 레그레이즈는 core 로 옮긴다. 데드리프트는 구간대로 등이다 —
/// 판단이라, 확인 줄이 부위마다 든 운동을 보인다.
const exercisePart = <String, String>{
  '벤치프레스': 'chest',
  '인클라인 벤치프레스': 'chest',
  '디클라인 벤치프레스': 'chest',
  '덤벨 프레스': 'chest',
  '인클라인 덤벨 프레스': 'chest',
  '체스트 프레스': 'chest',
  '펙덱 플라이': 'chest',
  '케이블 크로스오버': 'chest',
  '푸시업': 'chest',
  '데드리프트': 'back',
  '루마니안 데드리프트': 'back',
  '랫풀다운': 'back',
  '풀업': 'back',
  '친업': 'back',
  '바벨로우': 'back',
  '덤벨로우': 'back',
  '시티드 로우': 'back',
  '케이블 로우': 'back',
  '티바로우': 'back',
  '스쿼트': 'legs',
  '프론트 스쿼트': 'legs',
  '핵스쿼트': 'legs',
  '레그프레스': 'legs',
  '레그익스텐션': 'legs',
  '레그컬': 'legs',
  '런지': 'legs',
  '불가리안 스플릿 스쿼트': 'legs',
  '힙쓰러스트': 'legs',
  '카프레이즈': 'legs',
  '오버헤드프레스': 'shoulders',
  '숄더프레스': 'shoulders',
  '덤벨 숄더프레스': 'shoulders',
  '사이드 레터럴 레이즈': 'shoulders',
  '프론트 레이즈': 'shoulders',
  '벤트오버 레터럴 레이즈': 'shoulders',
  '업라이트 로우': 'shoulders',
  '슈러그': 'shoulders',
  '바벨컬': 'arms',
  '덤벨컬': 'arms',
  '해머컬': 'arms',
  '프리처컬': 'arms',
  '케이블컬': 'arms',
  '트라이셉스 익스텐션': 'arms',
  '케이블 푸시다운': 'arms',
  '딥스': 'arms',
  '킥백': 'arms',
  '플랭크': 'core',
  '사이드 플랭크': 'core',
  '크런치': 'core',
  '싯업': 'core',
  '행잉 레그레이즈': 'core',
  '러시안 트위스트': 'core',
  '레그레이즈': 'core',
  '러닝': 'cardio',
  '사이클': 'cardio',
  '로잉': 'cardio',
  '버피': 'cardio',
  '점핑잭': 'cardio',
};

/// 묶음 부위 → 든 부위. upper 는 가슴·등·어깨·팔, lower 는 하체다.
const partGroups = <String, Set<String>>{
  'upper': {'chest', 'back', 'shoulders', 'arms'},
  'lower': {'legs'},
};

/// 어느 언어의 사전 이름으로든 그 운동의 부위. 사전에 없는 이름은 null — 부위를
/// 지어내지 않는다.
String? partOf(String name) =>
    exercisePart[exerciseByName[name.trim().toLowerCase()]?.ko];

/// [part] 가 [name] 의 부위를 품는가. upper·lower 는 펼쳐서 본다.
bool inPart(String name, String part) {
  final p = partOf(name);
  return p != null && (partGroups[part]?.contains(p) ?? p == part);
}
