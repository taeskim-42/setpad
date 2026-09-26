/// 운동 → 근육(주동·보조)·기구·자세 팁. 몸 그림([anatomy.dart])이 쓰는 표다.
///
/// 2026-09-24 조사(ExRx.net 은 Internet Archive 보관본, ACE Exercise Library,
/// Concept2)에서 옮겼다. 규칙:
/// - primary: ExRx "Target" 근육이 속한 부위(같은 운동을 ExRx 가 두 근육 목록에 올린 경우 두 target 모두)
/// - secondary: ExRx "Synergists" 근육이 속한 부위 중 primary 가 아닌 것
///
/// 줄마다 위에 근거를 적었다 — 🟩 원문 근거(출처 열쇠와 원문 발췌), 🟦 해석(출처가
/// 없거나 다른 동작에서 옮김). 출처 열쇠의 주소는 파일 끝에 있다. 무게·횟수 처방과
/// 의학적 주장은 넣지 않았다. 유산소(러닝·사이클·로잉·버피·점핑잭)는 근육 표에 없다 —
/// 몸 그림은 그 세트를 유산소로 따로 센다.
library;

import 'exercises.dart' show Exercise;
import 'muscle_map_paths.dart' show Muscle;

/// 자세 팁 한 줄의 근거.
enum Basis {
  /// 🟩 이 운동의 출처 문장(주석에 출처 열쇠와 원문 발췌).
  source,

  /// 🟦 출처 문장을 옮겨 쓴 해석 — 비슷한 동작의 페이지이거나, 올바른 방법을
  /// 뒤집어 피할 것으로 쓴 것(주석에 그 출처와 원문).
  adapted,

  /// 🟦 출처 없이 덧붙인 말.
  none,
}

/// 자세 팁 한 줄.
typedef Cue = ({String ko, String en, Basis basis});

class Move {
  const Move({
    required this.primary,
    this.secondary = const [],
    this.primaryInterp = false,
    this.secondaryInterp = false,
    this.suggest = true,
    this.gear = const [],
    required this.sites,
    required this.cues,
    required this.mistakes,
    this.names,
    this.aliases = const [],
  });
  final List<Muscle> primary, secondary;

  /// 근육 배정이 🟦 해석이다(출처 목록을 부위로 나누거나 다른 동작에서 옮김).
  /// 화면은 그 역할 옆에 * 를 단다.
  final bool primaryInterp, secondaryInterp;

  /// 거짓이면 "이 부위를 주로 쓰는 운동" 에 올리지 않는다(셈에는 든다).
  final bool suggest;

  /// 사전 밖 운동의 기구(routineGear 의 값). 사전 운동은 비워 두고 routine.dart
  /// 의 exerciseGear 를 쓴다 — 표를 둘로 두지 않는다([moveGear]).
  final List<String> gear;

  /// 자세 팁 출처 사이트(화면 각주).
  final List<String> sites;
  final List<Cue> cues, mistakes;

  /// 이름 사전(exercises.dart) 밖 운동의 여덟 언어 이름. 사전 운동은 null.
  /// ko·en 밖의 이름은 조사자의 번역(🟦)이고 원어민 확인 전이다 — 화면은 그
  /// 언어에서 영어 이름을 쓰고, 기록 이름을 찾을 때만 쓴다.
  final Exercise? names;

  /// 사전 밖 운동의 별칭 — 하나에 한 이름.
  final List<String> aliases;
}

/// 한국어 이름 → 운동. 사전 운동의 열쇠는 exerciseKey 와 같다.
/// 사전에는 있지만 근육 표에는 없는 머신 — 근육 배정의 출처를 찾지 못했다(2026-09-26
/// 조사). 지어 넣지 않는다. 몸 그림은 이 운동의 세트를 '근육을 모르는 기록' 으로 센다.
const unsourcedMachines = {
  '그립 머신',
  '리버스 V 스쿼트',
  '펜듈럼 스쿼트',
  '벨트 스쿼트',
  '티비아 레이즈 머신',
  // 2차 조사(2026-09-26): ExRx·보관본(web.archive.org)·제조사 페이지가 이 환경의 망 정책으로
  // 막혀 원문을 열지 못했다 — 근육은 '확인 못 함'.
  '동키 레이즈',
  '버티컬 레그프레스',
  '런지 머신',
  '멀티 힙',
  '어퍼 백 로우',
  '잼머 프레스',
  '넥 머신',
};

/// 삼두의 세 머리. ExRx 는 "Triceps Brachii" 하나로 적는다 — 머리마다 같은 역할로 센다.
const tricepsHeads = [
  Muscle.tricepsLong,
  Muscle.tricepsLateral,
  Muscle.tricepsMedial,
];

const moves = <String, Move>{
  // 벤치프레스 (Bench Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, ...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/BBBenchPress "Dismount barbell from rack over upper chest"
      (
        ko: '바는 가슴 위쪽 위에서 랙에서 뺀다',
        en: 'Unrack the bar over your upper chest',
        basis: Basis.source,
      ),
      // 🟩 ace:5 "Press the feet into the ground and the hips into the bench"
      (
        ko: '발로 바닥을, 엉덩이로 벤치를 누른다',
        en: 'Press your feet into the floor and your hips into the bench',
        basis: Basis.source,
      ),
      // 🟩 ace:5 "Slowly lower the bar to the chest by allowing the elbows to bend out to the side"
      (
        ko: '팔꿈치를 옆으로 굽히며 바를 가슴까지 천천히 내린다',
        en: 'Lower the bar slowly to your chest, elbows bending out to the side',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/BBBenchPress "Press bar upward until arms are extended"
      (
        ko: '팔이 펴질 때까지 밀어 올린다',
        en: 'Press up until your arms are extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:PectoralSternal/BBBenchPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '가슴에서 바를 튕겨 올린다',
        en: 'Bouncing the bar off the chest',
        basis: Basis.none,
      ),
    ],
  ),
  // 인클라인 벤치프레스 (Incline Bench Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Clavicular
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Sternal, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '인클라인 벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, ...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Dismount barbell from rack over upper chest"
      (
        ko: '인클라인 벤치에 누워 바를 가슴 위쪽 위에서 뺀다',
        en: 'Lie on the incline bench and unrack over your upper chest',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Lower weight to upper chest"
      (
        ko: '바를 가슴 위쪽으로 내린다',
        en: 'Lower the bar to your upper chest',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Press bar until arms are extended"
      (
        ko: '팔이 펴질 때까지 밀어 올린다',
        en: 'Press until your arms are extended',
        basis: Basis.source,
      ),
      // 🟦 ← ace:25 "Depress and retract your scapulae (pull shoulders down and back) to make firm contact with the bench"
      (
        ko: '어깨를 뒤·아래로 당겨 벤치에 붙인다',
        en: 'Pull your shoulders back and down against the bench',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '바를 가슴 아래쪽이나 배 쪽으로 내린다',
        en: 'Lowering the bar toward the lower chest or belly',
        basis: Basis.none,
      ),
    ],
  ),
  // 디클라인 벤치프레스 (Decline Bench Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '디클라인 벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, ...tricepsHeads],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Lie supine on decline bench with feet under leg brace"
      (
        ko: '다리를 받침에 걸고 디클라인 벤치에 눕는다',
        en: 'Lie on the decline bench with your feet under the leg brace',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Lower weight to chest"
      (
        ko: '바를 가슴으로 내린다',
        en: 'Lower the bar to your chest',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Press bar until arms are extended"
      (
        ko: '팔이 펴질 때까지 밀어 올린다',
        en: 'Press until your arms are extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '바를 떨어뜨리듯 빠르게 내린다',
        en: 'Letting the bar drop fast instead of lowering it under control',
        basis: Basis.none,
      ),
    ],
  ),
  // 덤벨 프레스 (Dumbbell Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '덤벨 프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, ...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/DBBenchPress "Kick weights to shoulder and lie back"
      (
        ko: '덤벨을 허벅지에 올려 두었다가 무릎으로 밀어 올리며 눕는다',
        en: 'Rest the dumbbells on your thighs and kick them up as you lie back',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/DBBenchPress "Press dumbbells up with elbows to sides until arms are extended"
      (
        ko: '팔꿈치를 옆으로 두고 팔이 펴질 때까지 민다',
        en: 'Press with elbows to the sides until your arms are extended',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/DBBenchPress "Lower weight to sides of chest until slight stretch is felt in chest or shoulder"
      (
        ko: '가슴이나 어깨가 살짝 늘어나는 곳까지 내린다',
        en: 'Lower until you feel a slight stretch in your chest or shoulders',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/DBBenchPress "traveling inward over each shoulder at top"
      (
        ko: '올라가며 덤벨이 어깨 위로 모이는 약한 호를 그린다',
        en: 'Let the dumbbells travel in a slight arc, coming in over the shoulders at the top',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:19 "Gently touch the dumbbells to your chest without bouncing"
      (
        ko: '가슴에서 덤벨을 튕긴다',
        en: 'Bouncing the dumbbells off your chest',
        basis: Basis.source,
      ),
      // 🟩 ace:19 "Maintain a neutral wrist position"
      (
        ko: '손목이 뒤로 꺾인다',
        en: 'Letting the wrists bend back',
        basis: Basis.source,
      ),
    ],
  ),
  // 인클라인 덤벨 프레스 (Incline Dumbbell Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Clavicular
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Sternal, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '인클라인 덤벨 프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, ...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralClavicular/DBInclineBenchPress "Position dumbbells to sides of chest with upper arm under each dumbbell"
      (
        ko: '덤벨을 가슴 위쪽 옆에서 시작한다',
        en: 'Start with the dumbbells at the sides of your upper chest',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralClavicular/DBInclineBenchPress "Press dumbbells up with elbows to sides until arms are extended"
      (
        ko: '팔꿈치를 옆으로 두고 팔이 펴질 때까지 민다',
        en: 'Press with elbows to the sides until your arms are extended',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralClavicular/DBInclineBenchPress "Lower weight to sides of upper chest until slight stretch is felt in chest or shoulder"
      (
        ko: '가슴 위쪽이 살짝 늘어나는 곳까지 내린다',
        en: 'Lower to the sides of your upper chest until you feel a slight stretch',
        basis: Basis.source,
      ),
      // 🟩 ace:25 "Your head, shoulders, butt and feet should make contact with the bench and floor/riser throughout the exercise"
      (
        ko: '머리·어깨·엉덩이·발은 벤치와 바닥에 닿은 채로',
        en: 'Keep head, shoulders, hips and feet in contact with the bench and floor',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:25 "Gently touch the dumbbells to your chest without bouncing"
      (
        ko: '가슴에서 덤벨을 튕긴다',
        en: 'Bouncing the dumbbells off your chest',
        basis: Basis.source,
      ),
      // 🟩 ace:25 "Maintain a neutral wrist position"
      (
        ko: '손목이 뒤로 꺾인다',
        en: 'Letting the wrists bend back',
        basis: Basis.source,
      ),
    ],
  ),
  // 체스트 프레스 (Chest Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '체스트 프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, ...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/LVChestPress "Sit on seat with chest approximately height of horizontal handles"
      (
        ko: '손잡이가 가슴 높이에 오게 좌석을 맞춘다',
        en: 'Set the seat so the handles are at chest height',
        basis: Basis.source,
      ),
      // 🟩 ace:188 "Continue pressing until your elbows are fully extended, but not locked"
      (
        ko: '팔이 펴질 때까지 밀되 팔꿈치를 잠그지 않는다',
        en: 'Press until your arms are extended, without locking the elbows',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/LVChestPress "Return weight until chest muscles are slightly stretched"
      (
        ko: '가슴이 살짝 늘어나는 곳까지 되돌린다',
        en: 'Return until your chest is slightly stretched',
        basis: Basis.source,
      ),
      // 🟩 ace:188 "Depress and retract your scapulae (pull shoulders back and down)"
      (
        ko: '어깨를 뒤·아래로 당긴 채 유지한다',
        en: 'Keep your shoulders pulled back and down',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:188 "avoid arching your back throughout the exercise"
      (ko: '허리를 젖힌다', en: 'Arching the low back', basis: Basis.source),
      // 🟩 ace:188 "Your shoulder blades should continue to make contact with the backrest and not round or bend forward"
      (
        ko: '견갑골이 등받이에서 떨어지며 어깨가 앞으로 말린다',
        en: 'Letting the shoulder blades leave the backrest and round forward',
        basis: Basis.source,
      ),
    ],
  ),
  // 펙덱 플라이 (Pec Deck Fly)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Coracobrachialis, Pectoralis Minor, Serratus Anterior
  '펙덱 플라이': Move(
    primary: [Muscle.chest],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/LVPecDeckFly "Place forearms on padded lever"
      (
        ko: '등을 패드에 붙이고 팔뚝을 레버 패드에 댄다',
        en: 'Sit with your back on the pad and forearms on the padded levers',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/LVPecDeckFly "Push levers together"
      (ko: '레버를 가운데로 모은다', en: 'Push the levers together', basis: Basis.source),
      // 🟩 exrx:PectoralSternal/LVPecDeckFly "Return until chest muscles are stretched"
      (
        ko: '가슴이 늘어나는 곳까지 되돌린다',
        en: 'Return until your chest is stretched',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '되돌릴 때 레버가 반동으로 뒤로 튕겨 나간다',
        en: 'Letting the levers fly back with momentum',
        basis: Basis.none,
      ),
      // 🟦
      (ko: '어깨가 으쓱 올라간다', en: 'Shrugging the shoulders up', basis: Basis.none),
    ],
  ),
  // 케이블 크로스오버 (Cable Crossover)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Pectoralis Minor, Rhomboids, Levator Scapulae, Latissimus Dorsi, Coracobrachialis
  '케이블 크로스오버': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.upperBack, Muscle.lats],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/CBStandingFly "Bend over slightly by flexing hips and knees"
      (
        ko: '높은 도르래 두 개 사이에 서서 엉덩이·무릎을 살짝 굽혀 숙인다',
        en: 'Stand between two high pulleys and bend forward slightly at hips and knees',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/CBStandingFly "Bring cable attachments together in hugging motion with elbows in fixed position"
      (
        ko: '팔꿈치 각도를 고정한 채 껴안듯 손을 모은다',
        en: 'Keep the elbows fixed and bring the handles together in a hugging motion',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/CBStandingFly "Return to starting position until chest muscles are stretched"
      (
        ko: '가슴이 늘어나는 곳까지 되돌린다',
        en: 'Return until your chest is stretched',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '팔꿈치를 굽혔다 폈다 하며 미는 동작이 된다',
        en: 'Bending and straightening the elbows so it turns into a press',
        basis: Basis.none,
      ),
      // 🟩 exrx:PectoralSternal/CBStandingFly "struggling with backward pull of cables"
      (
        ko: '무거운 무게에 몸이 뒤로 끌려간다',
        en: 'Getting pulled backward by the cables under heavy load',
        basis: Basis.source,
      ),
    ],
  ),
  // 푸시업 (Push Up)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '푸시업': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, ...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/BWPushup "hands slightly wider than shoulder width"
      (
        ko: '손은 어깨너비보다 조금 넓게',
        en: 'Hands slightly wider than shoulder width',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/BWPushup "Keeping body straight"
      (
        ko: '머리부터 발까지 몸을 곧게 유지한다',
        en: 'Keep your body straight from head to feet',
        basis: Basis.source,
      ),
      // 🟩 ace:41 "Stiffen your torso by contracting your core/abdominal muscles"
      (
        ko: '복근·엉덩이·허벅지에 힘을 줘 몸통을 단단히 한다',
        en: 'Brace your abs, glutes and thighs to stiffen your torso',
        basis: Basis.source,
      ),
      // 🟩 ace:41 "think about pushing the floor away from you"
      (
        ko: '바닥을 밀어낸다는 느낌으로 올라온다',
        en: 'Think about pushing the floor away',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:41 "Do not allow your low back to sag or your hips to hike upwards"
      (
        ko: '허리가 처지거나 엉덩이가 솟는다',
        en: 'Letting the low back sag or the hips hike up',
        basis: Basis.source,
      ),
      // 🟩 ace:41 "Continue to lower yourself until your chest or chin touch the mat/floor"
      (ko: '끝까지 내려가지 않는다', en: 'Not lowering all the way', basis: Basis.source),
    ],
  ),
  // 데드리프트 (Deadlift)
  // 근육 🟩 주동 ← ExRx Target: Erector Spinae, Gluteus Maximus
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Quadriceps, Hamstrings (top half), Soleus, Quadriceps, Adductor Magnus, Hamstrings (top half), Soleus
  '데드리프트': Move(
    primary: [Muscle.lowerBack, Muscle.glutes],
    secondary: [
      Muscle.adductors,
      Muscle.quads,
      Muscle.hamstrings,
      Muscle.calves,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:ErectorSpinae/BBDeadlift "Target muscle is exercised isometrically."
      (
        ko: '허리 근육은 움직이지 않고 버티는(등척성) 역할이다',
        en: 'Your low-back muscles work isometrically — they hold, not move',
        basis: Basis.source,
      ),
      // 🟩 exrx:ErectorSpinae/BBDeadlift "Keep bar close to body"
      (
        ko: '바를 몸 가까이 둔다',
        en: 'Keep the bar close to your body',
        basis: Basis.source,
      ),
      // 🟩 exrx:ErectorSpinae/BBDeadlift "keep hips low, shoulders high, arms and back straight"
      (
        ko: '엉덩이는 낮게, 어깨는 높게, 팔과 등은 곧게',
        en: 'Hips low, shoulders high, arms and back straight',
        basis: Basis.source,
      ),
      // 🟩 exrx:ErectorSpinae/BBDeadlift "Knees should point same direction as feet throughout movement"
      (
        ko: '무릎은 발끝과 같은 방향을 향한다',
        en: 'Knees point the same way as your feet',
        basis: Basis.source,
      ),
      // 🟩 exrx:ErectorSpinae/BBDeadlift "Lift bar by extending hips and knees to full extension"
      (
        ko: '엉덩이와 무릎을 끝까지 펴서 선다',
        en: 'Stand up by fully extending hips and knees',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:ErectorSpinae/BBDeadlift "arms and back straight"
      (
        ko: '등이 굽은 채 끌어올린다',
        en: 'Pulling with a rounded back',
        basis: Basis.source,
      ),
      // 🟩 ace:6 "the glutes and the back of the thighs should feel the work, NOT the back"
      (
        ko: '엉덩이·허벅지 뒤가 아니라 허리에 힘이 몰린다',
        en: 'Feeling it mainly in the low back instead of the glutes and hamstrings',
        basis: Basis.source,
      ),
    ],
  ),
  // 루마니안 데드리프트 (Romanian Deadlift)
  // 근육 🟩 주동 ← ExRx Target: Gluteus Maximus, Hamstrings
  //      🟦 보조 ← ExRx Synergists: Hamstrings, Adductor Magnus, Gluteus Maximus, Adductor Magnus
  // 근육 출처: ace:317
  // ACE 가 루마니안 데드리프트의 주동근을 둔근·햄스트링으로 적었다. 보조근은 ExRx 가 "very similar" 라고 한 Straight-back Stiff-leg Deadlift 페이지에서 가져왔다(🟦 적용).
  '루마니안 데드리프트': Move(
    primary: [Muscle.glutes, Muscle.hamstrings],
    secondaryInterp: true,
    secondary: [Muscle.adductors],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:317 "keep a slight bend in both knees and a straight back"
      (
        ko: '무릎은 살짝 굽히고 등은 곧게 편 채 시작한다',
        en: 'Start with a slight knee bend and a straight back',
        basis: Basis.source,
      ),
      // 🟩 exrx:OlympicLifts/RomanianDeadlift "tracing front contour of legs through downward motion"
      (
        ko: '엉덩이를 뒤로 밀며 바를 다리 앞선을 따라 내린다',
        en: 'Push your hips back and slide the bar down along the front of your legs',
        basis: Basis.source,
      ),
      // 🟩 ace:317 "until feeling some tension along the back of the legs"
      (
        ko: '허벅지 뒤가 당기는 곳까지만 내린다',
        en: 'Lower only until you feel tension along the back of your legs',
        basis: Basis.source,
      ),
      // 🟩 ace:317 "push the heels into the floor and pull the knees backwards, keeping the bar very close to the body"
      (
        ko: '발뒤꿈치로 바닥을 밀며 바를 몸 가까이 붙여 일어선다',
        en: 'Drive your heels into the floor and keep the bar close as you stand',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:OlympicLifts/RomanianDeadlift "keep arms and back straight and chest high"
      (ko: '등이 굽는다', en: 'Letting the back round', basis: Basis.source),
      // 🟩 ace:317 "keeping the bar very close to the body"
      (
        ko: '바가 다리에서 멀어진다',
        en: 'Letting the bar drift away from your legs',
        basis: Basis.source,
      ),
    ],
  ),
  // 랫풀다운 (Lat Pulldown)
  // 근육 🟩 주동 ← ExRx Target: Latissimus Dorsi
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis, Biceps Brachii, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Coracobrachialis, Rhomboids, Levator Scapulae, Trapezius, Lower, Trapezius, Middle, Pectoralis Minor
  '랫풀다운': Move(
    primary: [Muscle.lats],
    secondary: [
      Muscle.biceps,
      Muscle.forearms,
      Muscle.upperBack,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.teresMajor,
      Muscle.rearDelts,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:158 "adjusting the thigh pad to fit firmly against the top of your thighs"
      (
        ko: '허벅지 패드를 허벅지에 밀착시킨다',
        en: 'Lock your thighs under the pad',
        basis: Basis.source,
      ),
      // 🟩 ace:158 "initiate the downward pull by first depressing (lower) your scapulae"
      (
        ko: '어깨를 먼저 내린 다음 바를 당긴다',
        en: 'Set your shoulders down first, then pull',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/CBFrontPulldown "Pull down cable bar to upper chest"
      (
        ko: '팔꿈치를 바닥 쪽으로 끌어내리며 바를 가슴 위쪽으로',
        en: 'Drive your elbows down and pull the bar to your upper chest',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/CBFrontPulldown "Return until arms and shoulders are fully extended"
      (
        ko: '팔과 어깨가 끝까지 펴질 때까지 되돌린다',
        en: 'Return until arms and shoulders are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:158 "Avoid any additional backwards lean during the pull movement"
      (
        ko: '당기면서 몸을 뒤로 더 젖힌다',
        en: 'Leaning further back as you pull',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/CBFrontPulldown "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        basis: Basis.source,
      ),
    ],
  ),
  // 풀업 (Pull Up)
  // 근육 🟩 주동 ← ExRx Target: Latissimus Dorsi
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis, Biceps Brachii, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Coracobrachialis, Rhomboids, Levator Scapulae, Trapezius, Lower, Trapezius, Middle, Pectoralis Minor
  '풀업': Move(
    primary: [Muscle.lats],
    secondary: [
      Muscle.biceps,
      Muscle.forearms,
      Muscle.upperBack,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.teresMajor,
      Muscle.rearDelts,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:191 "palms facing away from you"
      (
        ko: '손바닥이 앞을 보게 바를 잡는다',
        en: 'Grip the bar with palms facing away',
        basis: Basis.source,
      ),
      // 🟩 ace:191 "Depress and retract your scapulae (pull shoulders back and down)"
      (
        ko: '어깨를 뒤·아래로 내린 상태를 유지한다',
        en: 'Keep your shoulders pulled back and down',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/BWPullup "Pull body up until chin is above bar"
      (
        ko: '턱이 바를 넘을 때까지 당긴다',
        en: 'Pull until your chin is above the bar',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/BWPullup "Lower body until arms and shoulders are fully extended"
      (
        ko: '팔과 어깨가 다 펴질 때까지 내려온다',
        en: 'Lower until arms and shoulders are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:191 "avoid swinging your body during your upward pull"
      (
        ko: '몸을 흔들어 반동으로 올라간다',
        en: 'Swinging to use momentum',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/BWPullup "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        basis: Basis.source,
      ),
    ],
  ),
  // 친업 (Chin Up)
  // 근육 🟩 주동 ← ExRx Target: Latissimus Dorsi
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis, Teres Major, Deltoid, Posterior, Rhomboids, Levator Scapulae, Trapezius, Lower, Trapezius, Middle, Pectoralis Major, Sternal, Pectoralis Minor
  '친업': Move(
    primary: [Muscle.lats],
    secondary: [
      Muscle.biceps,
      Muscle.forearms,
      Muscle.upperBack,
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.chest,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "grasp bar with underhand shoulder width grip"
      (
        ko: '손바닥이 나를 보게 어깨너비로 잡는다',
        en: 'Grip shoulder width with palms facing you',
        basis: Basis.source,
      ),
      // 🟩 ace:190 "your abdominal muscles to stabilize your spine"
      (
        ko: '복근에 힘을 줘 몸통을 고정한다',
        en: 'Brace your abs to steady your spine',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "Pull body up until elbows are to sides"
      (
        ko: '팔꿈치가 옆구리에 올 때까지 당긴다',
        en: 'Pull until your elbows reach your sides',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "Lower body until arms and shoulders are fully extended"
      (
        ko: '팔과 어깨가 다 펴질 때까지 내려온다',
        en: 'Lower until arms and shoulders are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:190 "avoid swinging your body during your upward pull"
      (
        ko: '몸을 흔들어 반동으로 올라간다',
        en: 'Swinging to use momentum',
        basis: Basis.source,
      ),
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "Lower body until arms and shoulders are fully extended"
      (
        ko: '반만 내려온다',
        en: 'Stopping halfway on the way down',
        basis: Basis.source,
      ),
    ],
  ),
  // 바벨로우 (Barbell Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '바벨로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    primaryInterp: true,
    secondary: [
      Muscle.rearDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.teresMajor,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/BBBentOverRow "Bend knees slightly and bend over bar with back straight"
      (
        ko: '무릎을 살짝 굽히고 등을 곧게 편 채 숙인다',
        en: 'Bend your knees slightly and hinge over with a straight back',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/BBBentOverRow "Pull bar to upper waist"
      (
        ko: '바를 윗배 쪽으로 당긴다',
        en: 'Pull the bar to your upper waist',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/BBBentOverRow "Return until arms are extended and shoulders are stretched downward"
      (
        ko: '팔이 펴지고 어깨가 아래로 늘어날 때까지 내린다',
        en: 'Lower until your arms are straight and your shoulders stretch down',
        basis: Basis.source,
      ),
      // 🟩 ace:12 "keep the back flat as the bar is pulled towards the belly button"
      (
        ko: '당기는 내내 등을 평평하게',
        en: 'Keep your back flat throughout',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/BBBentOverRow "Knees are bent in effort to keep low back straight"
      (ko: '허리가 둥글게 말린다', en: 'Rounding the low back', basis: Basis.source),
      // 🟦
      (
        ko: '상체를 들어 올리며 반동으로 당긴다',
        en: 'Raising the torso to heave the bar up',
        basis: Basis.none,
      ),
    ],
  ),
  // 덤벨로우 (Dumbbell Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '덤벨로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    primaryInterp: true,
    secondary: [
      Muscle.rearDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.teresMajor,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/DBBentOverRow "placing knee and hand of supporting arm on bench"
      (
        ko: '한쪽 무릎과 손을 벤치에 올려 몸을 받친다',
        en: 'Support yourself with one knee and hand on the bench',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/DBBentOverRow "Torso should be close to horizontal"
      (
        ko: '상체는 바닥과 거의 수평으로',
        en: 'Keep your torso close to horizontal',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/DBBentOverRow "until it makes contact with ribs"
      (
        ko: '덤벨이 옆구리에 닿을 때까지 당긴다',
        en: 'Pull the dumbbell up until it touches your ribs',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/DBBentOverRow "Return until arm is extended and shoulder is stretched downward"
      (
        ko: '팔이 펴지고 어깨가 아래로 늘어날 때까지 내린다',
        en: 'Lower until the arm is straight and the shoulder stretches down',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/DBBentOverRow "do not rotate torso in effort to throw weight up"
      (
        ko: '몸통을 비틀어 덤벨을 던지듯 올린다',
        en: 'Twisting the torso to throw the weight up',
        basis: Basis.source,
      ),
      // 🟩 ace:126 "Your back should be flat"
      (ko: '등이 굽는다', en: 'Letting the back round', basis: Basis.source),
    ],
  ),
  // 시티드 로우 (Seated Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '시티드 로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    primaryInterp: true,
    secondary: [
      Muscle.rearDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.teresMajor,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/LVSeatedRow "Sit on seat and position chest against pad"
      (
        ko: '가슴을 패드에 대고 앉는다',
        en: 'Sit with your chest against the pad',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/LVSeatedRow "Pull lever back until elbows are behind back and shoulders are pulled back"
      (
        ko: '팔꿈치가 등 뒤로 갈 때까지 당기며 어깨를 뒤로',
        en: 'Pull until your elbows pass your back and your shoulders draw back',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/LVSeatedRow "lift chest slightly and pull shoulder blades together"
      (
        ko: '끝에서 가슴을 살짝 들고 견갑골을 모은다',
        en: 'At the end, lift your chest slightly and squeeze your shoulder blades together',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/LVSeatedRow "Return until arms are extended and shoulders are stretched forward"
      (
        ko: '팔이 펴지고 어깨가 앞으로 늘어날 때까지 되돌린다',
        en: 'Return until arms are extended and shoulders stretch forward',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:168 "Avoid leaning back and arching your low back"
      (ko: '몸을 뒤로 젖혀 당긴다', en: 'Leaning back to pull', basis: Basis.source),
      // 🟩 ace:168 "maintain a neutral wrist position"
      (ko: '손목이 꺾인다', en: 'Letting the wrists bend', basis: Basis.source),
    ],
  ),
  // 케이블 로우 (Cable Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Erector Spinae, Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '케이블 로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    primaryInterp: true,
    secondary: [
      Muscle.lowerBack,
      Muscle.rearDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.teresMajor,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/CBSeatedRow "positioning knees with slight bend"
      (
        ko: '발을 발판에 대고 무릎을 살짝 굽힌다',
        en: 'Feet on the platform, knees slightly bent',
        basis: Basis.source,
      ),
      // 🟩 ace:48 "pulling the elbows backwards close to the rib cage until the handle touches the front of the stomach"
      (
        ko: '팔꿈치를 갈비뼈 가까이 붙여 손잡이를 배 앞까지 당긴다',
        en: 'Pull the handle to your stomach with elbows close to your ribs',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/CBSeatedRow "Pull shoulders back and push chest forward"
      (
        ko: '당기며 가슴을 들고 어깨를 뒤로',
        en: 'Lift your chest and draw your shoulders back as you pull',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/CBSeatedRow "Begin with light weight and add additional weight gradually to allow lower back adequate adaptation"
      (
        ko: '가볍게 시작해 허리가 적응할 시간을 준다',
        en: 'Start light so your low back can adapt',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/CBSeatedRow "Do not pause or bounce at bottom of lift"
      (
        ko: '앞으로 뻗은 자리에서 멈추거나 튕긴다',
        en: 'Pausing or bouncing at the stretched position',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/CBSeatedRow "Do not lower weight beyond mild stretch"
      (
        ko: '가벼운 스트레칭을 넘어 앞으로 깊이 숙인다',
        en: 'Reaching forward past a mild stretch',
        basis: Basis.source,
      ),
    ],
  ),
  // 티바로우 (T-Bar Row)
  // 근육 🟦 주동 ← ExRx Target: General, Back
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '티바로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    primaryInterp: true,
    secondary: [
      Muscle.rearDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.teresMajor,
    ],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/LVTBarRow "Bend knees slightly and bend over lever handles with back straight"
      (
        ko: '무릎을 살짝 굽히고 등을 곧게 편 채 숙인다',
        en: 'Bend your knees slightly and hinge over with a straight back',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/LVTBarRow "Pull lever up to torso"
      (
        ko: '손잡이를 몸통 쪽으로 당긴다',
        en: 'Pull the handles to your torso',
        basis: Basis.source,
      ),
      // 🟩 exrx:BackGeneral/LVTBarRow "Return until arms are extended and shoulders are stretched downward"
      (
        ko: '팔이 펴지고 어깨가 아래로 늘어날 때까지 내린다',
        en: 'Lower until arms are straight and shoulders stretch down',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/LVTBarRow "Keep low back straight"
      (ko: '허리가 둥글게 말린다', en: 'Rounding the low back', basis: Basis.source),
      // 🟩 exrx:BackGeneral/LVTBarRow "Lighten load if torso raises beyond 45 degrees in order to complete repetition"
      (
        ko: '끝까지 들려고 상체를 45°보다 더 세운다 — 그럴 땐 무게를 줄인다',
        en: 'Raising the torso past 45° to finish a rep — lighten the load instead',
        basis: Basis.source,
      ),
    ],
  ),
  // 굿모닝 (Good Morning)
  // 근육 🟩 주동 ← ExRx Target: Hamstrings
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus
  '굿모닝': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.glutes, Muscle.adductors],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Hamstrings/BBGoodMorning "Position barbell on back of shoulders"
      (
        ko: '바를 어깨 뒤에 얹는다',
        en: 'Rest the bar on the back of your shoulders',
        basis: Basis.source,
      ),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Keeping back straight, bend hips to lower torso forward until parallel to floor"
      (
        ko: '등을 곧게 편 채 엉덩이를 굽혀 상체를 바닥과 평행까지 숙인다',
        en: 'Keeping your back straight, hinge at the hips until your torso is parallel to the floor',
        basis: Basis.source,
      ),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Do not lower weight beyond mild stretch through hamstrings"
      (
        ko: '햄스트링이 가볍게 늘어나는 곳까지만',
        en: 'Go only as far as a mild hamstring stretch',
        basis: Basis.source,
      ),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Begin with very light weight"
      (
        ko: '아주 가벼운 무게로 시작한다',
        en: 'Start with a very light weight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Hamstrings/BBGoodMorning "Throughout lift, keep back and knees straight"
      (ko: '등이 굽는다', en: 'Letting the back round', basis: Basis.source),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Full range of motion will vary from person to person depending on flexibility"
      (
        ko: '유연성보다 깊이 내려간다',
        en: 'Going deeper than your flexibility allows',
        basis: Basis.source,
      ),
    ],
  ),
  // 파워클린 (Power Clean)
  // 근육 출처: exrx:OlympicLifts/PowerClean
  // ExRx 는 근육 목록 없이 관절 동작만 적었다: 엉덩이·무릎 신전, 발목 저측굴곡, 어깨 외전·굴곡·외회전, 견갑 거상·상방회전, 팔꿈치 굴곡, 척추 신전(정적). 이 동작을 부위로 옮긴 것은 🟦. ACE 는 "Full Body/Integrated" 로만 적었다.
  '파워클린': Move(
    primary: [Muscle.glutes, Muscle.hamstrings, Muscle.quads, Muscle.traps],
    primaryInterp: true,
    secondaryInterp: true,
    // 해석한 근육이라 부위 추천에는 올리지 않는다 — 셈에만 든다.
    suggest: false,
    secondary: [
      Muscle.calves,
      Muscle.sideDelts,
      Muscle.frontDelts,
      Muscle.biceps,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:OlympicLifts/PowerClean "Position shoulders over bar with back arched tightly"
      (
        ko: '어깨를 바 위에 두고 등을 단단히 편다',
        en: 'Shoulders over the bar, back set tight',
        basis: Basis.source,
      ),
      // 🟩 exrx:OlympicLifts/PowerClean "Do not jerk weight from floor; arise steadily then accelerate"
      (
        ko: '바닥에서 확 잡아채지 말고 꾸준히 일어선 뒤 가속한다',
        en: 'Don\'t jerk it off the floor — rise steadily, then accelerate',
        basis: Basis.source,
      ),
      // 🟩 exrx:OlympicLifts/PowerClean "keeping bar close to body"
      (
        ko: '바를 몸 가까이 붙여 끌어올린다',
        en: 'Keep the bar close to your body',
        basis: Basis.source,
      ),
      // 🟩 ace:125 "snap the elbows forward"
      (
        ko: '팔꿈치를 앞으로 돌려 바를 어깨 앞에 받는다',
        en: 'Snap the elbows forward and catch the bar on the front of your shoulders',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:OlympicLifts/PowerClean "keeping barbell close to thighs"
      (
        ko: '바가 허벅지에서 멀어진다',
        en: 'Letting the bar swing away from the thighs',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '기술을 익히기 전에 무게부터 올린다',
        en: 'Adding weight before learning the technique',
        basis: Basis.none,
      ),
    ],
  ),
  // 스쿼트 (Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/BBSquat "position bar high on back of shoulders"
      (
        ko: '바는 어깨 뒤쪽 높게 얹고 어깨너비로 선다',
        en: 'Bar high on the back of your shoulders; stand shoulder width',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/BBSquat "Squat down by bending hips back while allowing knees to bend forward"
      (
        ko: '엉덩이를 뒤로 빼며 무릎을 앞으로 굽힌다',
        en: 'Sit the hips back while letting the knees bend forward',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/BBSquat "Knees should point same direction as feet throughout movement"
      (ko: '무릎은 발끝과 같은 방향으로', en: 'Knees track your toes', basis: Basis.source),
      // 🟩 ace:11 "keep the back straight and the chest up"
      (ko: '가슴을 들고 등을 곧게', en: 'Chest up, back straight', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/BBSquat "Knees should point same direction as feet"
      (ko: '무릎이 안쪽으로 모인다', en: 'Knees caving inward', basis: Basis.source),
      // 🟩 exrx:Quadriceps/BBSquat "feet flat on floor with equal distribution of weight"
      (ko: '뒤꿈치가 들린다', en: 'Heels lifting off the floor', basis: Basis.source),
    ],
  ),
  // 프론트 스쿼트 (Front Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '프론트 스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/BBFrontSquat "upper arms parallel to floor"
      (
        ko: '바를 어깨 앞에 얹고 위팔을 바닥과 평행하게',
        en: 'Rack the bar on the front of your shoulders, upper arms parallel to the floor',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/BBFrontSquat "Squat down by bending hips back while allowing knees to bend forward"
      (
        ko: '엉덩이를 뒤로 빼며 무릎을 앞으로 굽힌다',
        en: 'Sit the hips back while letting the knees bend forward',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/BBFrontSquat "Knees should point same direction as feet throughout movement"
      (ko: '무릎은 발끝과 같은 방향으로', en: 'Knees track your toes', basis: Basis.source),
      // 🟩 exrx:Quadriceps/BBFrontSquat "Keep head facing forward, back straight"
      (
        ko: '시선은 앞, 등은 곧게',
        en: 'Eyes forward, back straight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '팔꿈치가 떨어지며 상체가 앞으로 쏠린다',
        en: 'Elbows dropping so the torso tips forward',
        basis: Basis.none,
      ),
      // 🟩 exrx:Quadriceps/BBFrontSquat "feet flat on floor"
      (ko: '뒤꿈치가 들린다', en: 'Heels lifting off the floor', basis: Basis.source),
    ],
  ),
  // 핵스쿼트 (Hack Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '핵스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/SLHackSquat "Lie supine on back pad with shoulders under shoulder pad"
      (
        ko: '어깨를 패드 아래에 두고 발판에 발을 둔다',
        en: 'Shoulders under the pads, feet on the platform',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "Re-engage support lever in extended position before dismounting."
      (
        ko: '내려오기 전에 다리를 편 채 안전 레버를 다시 건다',
        en: 'Before getting off, re-engage the support lever with legs extended',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "bend hips and knees until knees are just short of complete flexion"
      (
        ko: '무릎이 완전히 굽기 직전까지 내린다',
        en: 'Lower until your knees are just short of full bend',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "pushing with both heel and forefoot"
      (
        ko: '뒤꿈치와 앞발 모두로 민다',
        en: 'Push through both heel and forefoot',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "Placing feet slightly high on platform emphasizes Gluteus Maximus"
      (
        ko: '발을 높게 두면 엉덩이, 낮게 두면 대퇴사두가 더 쓰인다',
        en: 'Feet higher works the glutes more; lower works the quads more',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/SLHackSquat "forces pelvis to pull away from back pad"
      (
        ko: '골반이 등 패드에서 떨어질 만큼 깊이 내려간다',
        en: 'Going so deep your pelvis pulls away from the back pad',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "Keep knees pointed same directions as feet"
      (
        ko: '무릎이 발끝과 다른 방향을 향한다',
        en: 'Knees pointing a different way from your feet',
        basis: Basis.source,
      ),
    ],
  ),
  // 레그프레스 (Leg Press)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps · ACE 154 primaryMuscles: "Gluteus Maximus (glutes),Hamstrings,Quadriceps (quads)" (출처가 갈려 합친다)
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '레그프레스': Move(
    primary: [Muscle.quads, Muscle.glutes, Muscle.hamstrings],
    secondary: [Muscle.adductors, Muscle.calves],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:154 "positioning your back and sacrum (tailbone) flat against the machine's backrest"
      (
        ko: '등과 꼬리뼈를 등받이에 붙인다',
        en: 'Keep your back and tailbone against the backrest',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SL45LegPress "Adjust safety brace and back support to accommodate near full range of motion without forcing hips to bend at waist."
      (
        ko: '안전 받침과 등받이를, 엉덩이가 허리에서 꺾이지 않고 거의 끝까지 움직이게 맞춘다',
        en: 'Set the safety brace and back support for near-full range without forcing your hips to bend at the waist',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SL45LegPress "Lower sled by flexing hips and knees until knees are just short of complete flexion"
      (
        ko: '무릎이 완전히 굽기 직전까지 내린다',
        en: 'Lower until your knees are just short of full bend',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SL45LegPress "Do not allow heels to raise off of platform"
      (
        ko: '뒤꿈치가 발판에서 뜨지 않게 민다',
        en: 'Push without letting your heels lift',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/SL45LegPress "Keep knees pointed same directions as feet"
      (
        ko: '무릎은 발끝과 같은 방향으로',
        en: 'Knees point the same way as your feet',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:154 "Do not hyperextend (lock-out) your knees"
      (
        ko: '무릎을 튕기듯 완전히 잠근다',
        en: 'Snapping the knees into lockout',
        basis: Basis.source,
      ),
      // 🟩 ace:154 "avoid lifting your butt off the seat pad or rounding out your low back"
      (
        ko: '엉덩이가 들리거나 허리가 말린다',
        en: 'Hips lifting off the seat or the low back rounding',
        basis: Basis.source,
      ),
    ],
  ),
  // 레그익스텐션 (Leg Extension)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: None
  '레그익스텐션': Move(
    primary: [Muscle.quads],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/LVLegExtension "Position knee articulation at same axis as lever fulcrum"
      (
        ko: '무릎 관절을 기계 회전축에 맞춘다',
        en: 'Line your knee joint up with the machine\'s pivot',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/LVLegExtension "Place front of lower legs under padded lever"
      (
        ko: '패드를 정강이 앞 아래쪽에 댄다',
        en: 'Pad on the front of your lower legs',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/LVLegExtension "extending knees until legs are straight"
      (
        ko: '다리가 펴질 때까지 들어 올린다',
        en: 'Raise until your legs are straight',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/LVLegExtension "prevent body rising off of seat"
      (
        ko: '손잡이를 잡아 엉덩이가 뜨지 않게',
        en: 'Hold the handles so your hips stay on the seat',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '반동으로 차올린다',
        en: 'Kicking the weight up with momentum',
        basis: Basis.none,
      ),
      // 🟦
      (
        ko: '내릴 때 무게를 툭 떨어뜨린다',
        en: 'Dropping the weight on the way down',
        basis: Basis.none,
      ),
    ],
  ),
  // 레그컬 (Leg Curl)
  // 근육 🟩 주동 ← ExRx Target: Hamstrings, Hamstrings
  //      🟩 보조 ← ExRx Synergists: Gastrocnemius, Sartorius, Gracilis, Popliteus, Gastrocnemius, Gracilis, Sartorius, Popliteus
  '레그컬': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.calves, Muscle.adductors],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:153 "aligning the mid-point of your knee joint with the axis of rotation"
      (
        ko: '무릎 관절을 기계 회전축에 맞춘다',
        en: 'Line your knee joint up with the machine\'s pivot',
        basis: Basis.source,
      ),
      // 🟩 exrx:Hamstrings/LVSeatedLegCurl "Position lever pad so it makes contact with lowers leg just above ankles"
      (
        ko: '패드는 발목 바로 위에 댄다',
        en: 'The pad sits on the lower leg just above the ankle',
        basis: Basis.source,
      ),
      // 🟩 exrx:Hamstrings/LVLyingLegCurl "Raise lever pad to back of thighs by flexing knees"
      (
        ko: '무릎을 굽혀 패드를 허벅지 뒤로 당긴다',
        en: 'Curl the pad toward the back of your thighs',
        basis: Basis.source,
      ),
      // 🟩 ace:153 "slowly return to your starting position by lowering the resistance pads in a controlled manner"
      (ko: '천천히 되돌린다', en: 'Return slowly', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 ace:153 "Avoid arching your back during this movement"
      (ko: '허리를 젖힌다', en: 'Arching the low back', basis: Basis.source),
      // 🟩 exrx:Hamstrings/LVLyingLegCurl "Keep torso on bench to reduce hyperextension of lower back"
      (
        ko: '몸통이 벤치에서 뜬다(누워서 할 때)',
        en: 'Letting the torso come off the bench (lying version)',
        basis: Basis.source,
      ),
    ],
  ),
  // 런지 (Lunge)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '런지': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/DBLunge "Land on heel, then forefoot"
      (
        ko: '한 발을 앞으로 내딛어 뒤꿈치부터 딛는다',
        en: 'Step forward and land heel first',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/DBLunge "until knee of rear leg is almost in contact with floor"
      (
        ko: '뒷무릎이 바닥에 거의 닿을 때까지 내려간다',
        en: 'Lower until your back knee nearly touches the floor',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/DBLunge "Keep torso upright during lunge"
      (ko: '상체를 세운다', en: 'Keep your torso upright', basis: Basis.source),
      // 🟩 exrx:Quadriceps/DBLunge "A long lunge emphasizes Gluteus Maximus; short lunge emphasizes Quadriceps"
      (
        ko: '보폭이 길면 엉덩이, 짧으면 대퇴사두가 더 쓰인다',
        en: 'A long step works the glutes more; a short step the quads',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/DBLunge "Lead knee should point same direction as foot throughout lunge"
      (
        ko: '앞무릎이 안쪽으로 꺾인다',
        en: 'Front knee caving inward',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/DBLunge "Keep torso upright during lunge"
      (ko: '상체가 앞으로 무너진다', en: 'Torso collapsing forward', basis: Basis.source),
    ],
  ),
  // 불가리안 스플릿 스쿼트 (Bulgarian Split Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps · ACE 366 primaryMuscles: "Gluteus Maximus (glutes)" (출처가 갈려 둘 다 주동)
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '불가리안 스플릿 스쿼트': Move(
    primary: [Muscle.quads, Muscle.glutes],
    secondary: [Muscle.adductors, Muscle.calves],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "Extend leg back and place top of foot on bench"
      (
        ko: '뒷발등을 벤치에 올린다',
        en: 'Place the top of your back foot on a bench',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "Keep majority of bodyweight on forward leg, using rear leg primarily for balance"
      (
        ko: '체중은 대부분 앞다리에, 뒷다리는 균형용',
        en: 'Keep most of your weight on the front leg; the back leg is for balance',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "until knee of rear leg is almost in contact with floor"
      (
        ko: '뒷무릎이 바닥에 거의 닿을 때까지 내려간다',
        en: 'Lower until the back knee nearly touches the floor',
        basis: Basis.source,
      ),
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "Forward knee should point same direction as foot throughout movement"
      (
        ko: '앞무릎은 발끝과 같은 방향으로',
        en: 'Front knee tracks the foot',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "using rear leg primarily for balance"
      (
        ko: '뒷다리로 밀어 올라온다',
        en: 'Pushing up with the back leg',
        basis: Basis.source,
      ),
      // 🟩 ace:366 "Keep the back straight while lowering"
      (ko: '등이 굽는다', en: 'Rounding the back', basis: Basis.source),
    ],
  ),
  // 힙쓰러스트 (Hip Thrust)
  // 근육 🟩 주동 ← ExRx Target: Gluteus Maximus
  //      🟩 보조 ← ExRx Synergists: Quadriceps
  '힙쓰러스트': Move(
    primary: [Muscle.glutes],
    secondary: [Muscle.quads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Position upper back on corner of bench"
      (
        ko: '등 윗부분을 벤치 모서리에 기댄다',
        en: 'Rest your upper back on the edge of the bench',
        basis: Basis.source,
      ),
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Bar should be positioned across upper hip flexors and lower abdomen"
      (
        ko: '바는 골반 앞(아랫배 쪽)에, 필요하면 패드를 댄다',
        en: 'Place the bar across your hip crease; pad it if needed',
        basis: Basis.source,
      ),
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Place feet on floor approximately shoulder width with knees bent"
      (
        ko: '발은 어깨너비, 무릎은 굽힌다',
        en: 'Feet about shoulder width, knees bent',
        basis: Basis.source,
      ),
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Raise bar upward by extending hips until straight"
      (
        ko: '엉덩이가 곧게 펴질 때까지 들어 올린다',
        en: 'Drive up until your hips are straight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Bench may need to be secured so it does not slide on floor"
      (
        ko: '벤치가 미끄러진다',
        en: 'Letting the bench slide on the floor',
        basis: Basis.source,
      ),
      // 🟦 ← ace:49 "Avoid pushing your hips too high as this generally increases the amount of hyperextension (arching) in your low back"
      (
        ko: '엉덩이를 과하게 올려 허리가 꺾인다',
        en: 'Pushing the hips so high the low back arches',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 카프레이즈 (Calf Raise)
  // 근육 🟩 주동 ← ExRx Target: Gastrocnemius
  //      🟩 보조 ← ExRx Synergists: Soleus
  '카프레이즈': Move(
    primary: [Muscle.calves],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Position toes and balls of feet on calf block with arches and heels extending off"
      (
        ko: '앞발만 발판에 올리고 뒤꿈치는 밖으로',
        en: 'Balls of your feet on the block, heels hanging off',
        basis: Basis.source,
      ),
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Raise heels by extending ankles as high as possible"
      (
        ko: '뒤꿈치를 최대한 높이 든다',
        en: 'Raise your heels as high as possible',
        basis: Basis.source,
      ),
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Lower heels by bending ankles until calves are stretched"
      (
        ko: '종아리가 늘어날 때까지 뒤꿈치를 내린다',
        en: 'Lower until your calves are stretched',
        basis: Basis.source,
      ),
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Keep knees straight throughout exercise"
      (ko: '무릎은 편 상태로', en: 'Keep your knees straight', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Quadriceps serve as synergist muscle if knees are bent slightly during stretch"
      (
        ko: '무릎을 굽혀 허벅지 힘을 보탠다',
        en: 'Bending the knees so the thighs help',
        basis: Basis.source,
      ),
      // 🟦
      (ko: '가동 범위를 반만 쓴다', en: 'Using only half the range', basis: Basis.none),
    ],
  ),
  // 레그레이즈 (Leg Raise)
  // 근육 🟩 주동 ← ExRx Target: Iliopsoas
  //      🟩 보조 ← ExRx Synergists: Tensor Fasciae Latae, Pectineus, Sartorius, Adductor Longus, Adductor Brevis
  // ExRx 기준 주동근은 고관절 굴곡근이다. 복근은 허리를 말아 올릴 때만 동적으로 일한다.
  '레그레이즈': Move(
    primary: [Muscle.hipFlexors],
    secondary: [Muscle.adductors],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Place hands under lower buttock on each side to support pelvis"
      (
        ko: '벤치에 누워 손을 엉덩이 아래 양옆에 넣어 골반을 받친다',
        en: 'Lie on a bench with your hands under your lower buttocks to support the pelvis',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Raise legs by flexing hips and knees"
      (
        ko: '엉덩이와 무릎을 굽혀 다리를 올린다',
        en: 'Raise your legs by bending hips and knees',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Return until hips and knees are extended"
      (
        ko: '엉덩이·무릎이 펴질 때까지 되돌린다',
        en: 'Return until hips and knees are straight',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Rectus Abdominis and Obliques only contract dynamically if actual waist flexion occurs"
      (
        ko: '복근을 쓰려면 골반까지 말아 올린다',
        en: 'To work the abs, curl the pelvis up too',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "With no waist flexion, Rectus Abdominis and External Oblique will only act to stabilize"
      (
        ko: '다리만 오르내리며 복근 운동이라고 여긴다',
        en: 'Treating hip-only lifting as an ab exercise',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '내릴 때 다리를 툭 떨어뜨린다',
        en: 'Dropping the legs on the way down',
        basis: Basis.none,
      ),
    ],
  ),
  // 오버헤드프레스 (Overhead Press)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Anterior
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Triceps Brachii, Deltoid, Lateral, Coracobrachialis, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations
  '오버헤드프레스': Move(
    primary: [Muscle.frontDelts],
    secondary: [
      Muscle.chest,
      ...tricepsHeads,
      Muscle.sideDelts,
      Muscle.upperBack,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "Position bar in front of neck"
      (
        ko: '어깨너비보다 조금 넓게 잡고 바를 목 앞에 둔다',
        en: 'Grip slightly wider than shoulder width, bar in front of your neck',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "Press bar upward until arms are extended overhead"
      (
        ko: '팔이 펴질 때까지 머리 위로 밀어 올린다',
        en: 'Press overhead until your arms are extended',
        basis: Basis.source,
      ),
      // 🟩 ace:71 "keeping the back straight and tall"
      (
        ko: '등을 곧게 세운다',
        en: 'Stand tall with a straight back',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "Lower to front of neck"
      (
        ko: '다시 목 앞으로 내린다',
        en: 'Lower back to the front of your neck',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:71 "press the barbell directly overhead"
      (
        ko: '바를 머리 위가 아니라 앞으로 밀어낸다',
        en: 'Pressing the bar out in front instead of straight overhead',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "until arms are extended overhead"
      (
        ko: '팔을 끝까지 펴지 않는다',
        en: 'Not extending the arms fully overhead',
        basis: Basis.source,
      ),
    ],
  ),
  // 숄더프레스 (Shoulder Press)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Anterior
  //      🟩 보조 ← ExRx Synergists: Deltoid, Lateral, Supraspinatus, Pectoralis Major, Clavicular, Triceps Brachii, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations
  '숄더프레스': Move(
    primary: [Muscle.frontDelts],
    secondary: [
      Muscle.sideDelts,
      Muscle.chest,
      ...tricepsHeads,
      Muscle.upperBack,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:186 "Adjust the seat height so that the handles are level with your shoulders or just higher than your shoulders"
      (
        ko: '손잡이가 어깨 높이나 조금 위에 오게 좌석을 맞춘다',
        en: 'Set the seat so the handles are at or just above shoulder height',
        basis: Basis.source,
      ),
      // 🟩 ace:186 "slightly forward than the 3 and 9 o'clock positions"
      (
        ko: '팔꿈치를 몸 옆선보다 조금 앞에 둔다',
        en: 'Keep your elbows slightly in front of your sides',
        basis: Basis.source,
      ),
      // 🟩 ace:186 "Continue pressing until your elbows are fully extended, but not locked"
      (
        ko: '팔꿈치를 잠그지 않고 팔을 편다',
        en: 'Press until your elbows are extended, not locked',
        basis: Basis.source,
      ),
      // 🟩 ace:186 "Depress and retract your scapulae (pull shoulders back and down)"
      (
        ko: '어깨를 뒤·아래로 당긴 채',
        en: 'Keep your shoulders pulled back and down',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidAnterior/LVShoulderPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        basis: Basis.source,
      ),
      // 🟩 ace:186 "avoid arching your back throughout the exercise"
      (
        ko: '허리를 젖혀 민다',
        en: 'Arching the low back to press',
        basis: Basis.source,
      ),
    ],
  ),
  // 덤벨 숄더프레스 (Dumbbell Shoulder Press)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Anterior
  //      🟩 보조 ← ExRx Synergists: Deltoid, Lateral, Supraspinatus, Triceps Brachii, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations, Pectoralis Major, Clavicular, Coracobrachialis
  '덤벨 숄더프레스': Move(
    primary: [Muscle.frontDelts],
    secondary: [
      Muscle.sideDelts,
      ...tricepsHeads,
      Muscle.upperBack,
      Muscle.chest,
    ],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "Position dumbbells to each side of shoulders with elbows below wrists"
      (
        ko: '덤벨은 어깨 옆에, 팔꿈치는 손목 아래에',
        en: 'Dumbbells beside your shoulders, elbows under your wrists',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "Press dumbbells upward until arms are extended overhead"
      (
        ko: '팔이 펴질 때까지 머리 위로 민다',
        en: 'Press overhead until your arms are extended',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "Lower to sides of shoulders"
      (
        ko: '다시 어깨 옆으로 내린다',
        en: 'Lower back to the sides of your shoulders',
        basis: Basis.source,
      ),
      // 🟦 ← ace:43 "Press the feet into the floor, squeeze the stomach muscles"
      (
        ko: '배에 힘을 주고 발로 바닥을 누른다',
        en: 'Brace your stomach and press your feet into the floor',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "elbows below wrists"
      (
        ko: '팔꿈치가 손목 아래를 벗어난다',
        en: 'Letting the elbows drift out from under the wrists',
        basis: Basis.source,
      ),
      // 🟦
      (ko: '허리를 크게 젖힌다', en: 'Arching the low back hard', basis: Basis.none),
    ],
  ),
  // 사이드 레터럴 레이즈 (Lateral Raise)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Lateral
  //      🟩 보조 ← ExRx Synergists: Deltoid, Anterior, Supraspinatus, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations
  '사이드 레터럴 레이즈': Move(
    primary: [Muscle.sideDelts],
    secondary: [Muscle.frontDelts, Muscle.upperBack],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "maintaining slight bend through elbows"
      (
        ko: '팔꿈치를 살짝 굽힌 각도로 고정한다',
        en: 'Keep a slight, fixed bend in the elbows',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "Raise upper arms to sides until slightly bent elbows are shoulder height"
      (
        ko: '팔꿈치가 어깨 높이가 될 때까지 옆으로 든다',
        en: 'Raise to the sides until your elbows reach shoulder height',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "maintaining elbows' height above or equal to wrists"
      (
        ko: '팔꿈치를 손목과 같거나 높게',
        en: 'Keep your elbows at or above wrist height',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "To keep resistance targeted to side delt, torso is bent over slightly"
      (
        ko: '상체를 살짝 숙인다',
        en: 'Lean your torso forward slightly',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "If elbows drop lower than wrists, front deltoids become primary mover instead of lateral deltoids"
      (
        ko: '팔꿈치가 손목보다 떨어져 앞어깨가 대신 든다',
        en: 'Elbows dropping below the wrists so the front delts take over',
        basis: Basis.source,
      ),
      // 🟩 ace:26 "no arching your low back"
      (
        ko: '허리를 젖혀 반동을 쓴다',
        en: 'Arching the low back to swing the weights up',
        basis: Basis.source,
      ),
    ],
  ),
  // 프론트 레이즈 (Front Raise)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Anterior
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Lateral, Coracobrachialis, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations
  '프론트 레이즈': Move(
    primary: [Muscle.frontDelts],
    secondary: [Muscle.chest, Muscle.sideDelts, Muscle.upperBack],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidAnterior/DBFrontRaise "Position dumbbells in front of upper legs with elbows straight or slightly bent"
      (
        ko: '덤벨을 허벅지 앞에 두고 팔꿈치는 펴거나 살짝 굽힌다',
        en: 'Dumbbells in front of your thighs, elbows straight or slightly bent',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidAnterior/DBFrontRaise "Raise dumbbells forward and upward until upper arms are above horizontal"
      (
        ko: '위팔이 수평보다 조금 위까지 앞으로 든다',
        en: 'Raise forward until your upper arms are just above horizontal',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidAnterior/DBFrontRaise "Raise should be limited to height achieved just before tightness is felt in shoulder capsule"
      (
        ko: '어깨가 조이는 느낌 직전에서 멈춘다',
        en: 'Stop just before you feel tightness in the shoulder',
        basis: Basis.source,
      ),
      // 🟩 ace:54 "Stiffen your torso by contracting your abdominal/core muscles"
      (
        ko: '배에 힘을 줘 몸통을 단단히',
        en: 'Brace to stiffen your torso',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:54 "no arching of your low back"
      (
        ko: '허리를 젖혀 반동을 쓴다',
        en: 'Arching the low back to swing up',
        basis: Basis.source,
      ),
      // 🟩 ace:54 "avoid flexion and extension of your wrists"
      (ko: '손목을 꺾는다', en: 'Bending the wrists', basis: Basis.source),
    ],
  ),
  // 벤트오버 레터럴 레이즈 (Bent Over Lateral Raise)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Posterior
  //      🟩 보조 ← ExRx Synergists: Infraspinatus, Teres Minor, Deltoid, Lateral, Trapezius, Middle, Trapezius, Lower, Rhomboids
  '벤트오버 레터럴 레이즈': Move(
    primary: [Muscle.rearDelts],
    secondary: [
      Muscle.upperBack,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.sideDelts,
    ],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "bend over through hips with back flat, close to horizontal"
      (
        ko: '무릎을 굽히고 등을 편 채 상체를 거의 수평까지 숙인다',
        en: 'Bend your knees and hinge over with a flat back, torso close to horizontal',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Position elbows with slight bend and palms facing together"
      (
        ko: '팔꿈치를 살짝 굽혀 고정하고 손바닥은 마주 보게',
        en: 'Slight fixed elbow bend, palms facing each other',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Maintain upper arms perpendicular to torso"
      (
        ko: '팔을 몸통과 직각으로, 팔꿈치가 어깨 높이까지 옆으로 든다',
        en: 'Raise to the sides, arms perpendicular to the torso, until elbows reach shoulder height',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Maintain height of elbows above wrists"
      (
        ko: '팔꿈치를 손목보다 높게',
        en: 'Keep your elbows above your wrists',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Positioning torso at 45° is not sufficient angle to target rear deltoids"
      (
        ko: '상체를 45° 정도만 숙인다 — 뒤어깨를 겨냥하기엔 부족',
        en: 'Only leaning to about 45° — not enough to target the rear delts',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Upper arm should travel in perpendicular path to torso to minimize relatively powerful latissimus dorsi involvement"
      (
        ko: '팔이 몸통 쪽으로 붙어 광배가 대신 든다',
        en: 'Arms drifting toward the torso so the lats take over',
        basis: Basis.source,
      ),
    ],
  ),
  // 업라이트 로우 (Upright Row)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Lateral
  //      🟩 보조 ← ExRx Synergists: Deltoid, Anterior, Supraspinatus, Brachialis, Brachioradialis, Biceps Brachii, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations, Infraspinatus, Teres Minor
  // 그립·자세는 ExRx "Upright Row Safety"(exrx:WeightTraining/Safety)를 따른다 — 운동 페이지의
  // "shoulder width or slightly narrower" 보다 이 안전 글이 좁은 그립의 어깨 충돌 위험을 적었다.
  '업라이트 로우': Move(
    primary: [Muscle.sideDelts],
    secondary: [
      Muscle.frontDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.upperBack,
      Muscle.infraspinatus,
      Muscle.teresMinor,
    ],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:WeightTraining/Safety "A shoulder width grip is suggested when performing the upright row" /
      //    "a medium to slightly wide grip can facilitate a more ideal shoulder posture"
      (
        ko: '어깨너비나 조금 넓게 오버그립',
        en: 'Overhand grip, shoulder width or slightly wider',
        basis: Basis.source,
      ),
      // 🟩 exrx:WeightTraining/Safety "An upright posture with chest high and shoulders back, bar kept close to the body"
      (
        ko: '가슴을 들고 어깨를 뒤로, 바는 몸 가까이',
        en: 'Chest up, shoulders back, bar close to your body',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidLateral/BBUprightRow "Pull bar to neck with elbows leading"
      (
        ko: '팔꿈치가 먼저 올라가게 바를 목 쪽으로 당긴다',
        en: 'Pull the bar toward your neck, elbows leading',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidLateral/BBUprightRow "Allow wrists to flex as bar rises"
      (
        ko: '바가 올라가며 손목이 자연스럽게 굽게 둔다',
        en: 'Let your wrists flex as the bar rises',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:WeightTraining/Safety "The greater internal rotation required for a close grip upright row decreases the subacromial space"
      (
        ko: '좁은 그립으로 당긴다 — 어깨 안쪽 공간이 좁아진다',
        en: 'Pulling with a close grip — it narrows the space in the shoulder joint',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '몸을 흔들어 반동을 쓴다',
        en: 'Swinging the body for momentum',
        basis: Basis.none,
      ),
    ],
  ),
  // 슈러그 (Shrug)
  // 근육 🟩 주동 ← ExRx Target: Trapezius, Upper
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Levator Scapulae
  '슈러그': Move(
    primary: [Muscle.traps],
    secondary: [Muscle.upperBack],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:TrapeziusUpper/BBShrug "shoulder width or slightly wider"
      (
        ko: '어깨너비나 조금 넓게 바를 잡고 선다',
        en: 'Hold the bar shoulder width or slightly wider',
        basis: Basis.source,
      ),
      // 🟩 ace:72 "raise the shoulders directly upwards to the ears"
      (
        ko: '어깨를 귀 쪽으로 곧게 들어 올린다',
        en: 'Raise your shoulders straight up toward your ears',
        basis: Basis.source,
      ),
      // 🟩 ace:72 "lowering slowly to the original starting position"
      (ko: '천천히 내린다', en: 'Lower slowly', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 ace:72 "DO NOT roll the shoulders"
      (ko: '어깨를 돌린다', en: 'Rolling the shoulders', basis: Basis.source),
      // 🟦 ← ace:75 "avoiding any shoulder rotation or elbow flexion"
      (
        ko: '팔꿈치를 굽혀 팔로 당긴다',
        en: 'Bending the elbows to pull with the arms',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 바벨컬 (Barbell Curl)
  // 근육 🟩 주동 ← ExRx Target: Biceps Brachii
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis
  '바벨컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Biceps/BBCurl "Grasp bar with shoulder width underhand grip"
      (
        ko: '어깨너비 언더그립',
        en: 'Underhand grip, shoulder width',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/BBCurl "With elbows to side, raise bar until forearms are vertical"
      (
        ko: '팔꿈치를 옆구리에 둔 채 팔뚝이 수직이 될 때까지 든다',
        en: 'Elbows at your sides, curl until your forearms are vertical',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/BBCurl "Lower until arms are fully extended"
      (
        ko: '팔이 다 펴질 때까지 내린다',
        en: 'Lower until your arms are fully extended',
        basis: Basis.source,
      ),
      // 🟩 ace:70 "Keep chest still, using just the arms for the movement"
      (
        ko: '가슴은 가만히, 팔만 움직인다',
        en: 'Keep your chest still — only the arms move',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:70 "Keep chest still"
      (
        ko: '상체를 흔들어 반동으로 든다',
        en: 'Swinging the torso to heave the bar',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/BBCurl "Lower until arms are fully extended"
      (ko: '끝까지 내리지 않는다', en: 'Not lowering all the way', basis: Basis.source),
    ],
  ),
  // 덤벨컬 (Dumbbell Curl)
  // 근육 🟩 주동 ← ExRx Target: Biceps Brachii
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis
  '덤벨컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Biceps/DBCurl "Position two dumbbells to sides, palms facing in"
      (
        ko: '덤벨을 옆에 두고 손바닥은 안쪽',
        en: 'Dumbbells at your sides, palms facing in',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/DBCurl "rotate forearm until forearm is vertical and palm faces shoulder"
      (
        ko: '팔꿈치를 옆구리에 둔 채 들며 손바닥이 어깨를 보게 돌린다',
        en: 'Elbows at your sides; curl and turn until the palm faces your shoulder',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/DBCurl "Biceps may be exercised alternating (as described), simultaneous"
      (
        ko: '번갈아 해도, 동시에 해도 된다',
        en: 'Alternate or lift both together',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/DBCurl "Lower to original position"
      (ko: '처음 자리까지 내린다', en: 'Lower back to the start', basis: Basis.source),
    ],
    mistakes: [
      // 🟦 ← exrx:Biceps/DBCurl "When elbow is fully flexed, it can travel forward slightly"
      (
        ko: '팔꿈치가 앞으로 크게 나간다',
        en: 'Elbows swinging far forward',
        basis: Basis.adapted,
      ),
      // 🟦
      (
        ko: '몸을 흔들어 반동을 쓴다',
        en: 'Swinging the body for momentum',
        basis: Basis.none,
      ),
    ],
  ),
  // 해머컬 (Hammer Curl)
  // 근육 🟩 주동 ← ExRx Target: Brachioradialis · ACE 10 primaryMuscles: "Biceps" (출처가 갈려 둘 다 주동)
  //      🟩 보조 ← ExRx Synergists: Brachialis, Biceps Brachii
  '해머컬': Move(
    primary: [Muscle.forearms, Muscle.biceps],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:10 "palms facing your body"
      (
        ko: '손바닥이 몸을 보게 덤벨을 쥔다',
        en: 'Hold the dumbbells with palms facing your body',
        basis: Basis.source,
      ),
      // 🟩 exrx:Brachioradialis/DBHammerCurl "raise one dumbbell until forearm is vertical and thumb faces shoulder"
      (
        ko: '엄지가 어깨를 향할 때까지 든다',
        en: 'Curl until your thumb faces your shoulder',
        basis: Basis.source,
      ),
      // 🟩 exrx:Brachioradialis/DBHammerCurl "With elbows to sides"
      (ko: '팔꿈치는 옆구리에', en: 'Elbows stay at your sides', basis: Basis.source),
      // 🟩 ace:10 "avoid shrugging your shoulders throughout the movement"
      (ko: '어깨를 으쓱하지 않는다', en: 'Don\'t shrug', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 ace:10 "without moving your elbows forward"
      (
        ko: '팔꿈치가 앞으로 나간다',
        en: 'Moving the elbows forward',
        basis: Basis.source,
      ),
      // 🟩 ace:10 "keeping your torso erect (no arching your low back)"
      (
        ko: '허리를 젖혀 든다',
        en: 'Arching the low back to lift',
        basis: Basis.source,
      ),
    ],
  ),
  // 프리처컬 (Preacher Curl)
  // 근육 🟩 주동 ← ExRx Target: Brachialis
  //      🟩 보조 ← ExRx Synergists: Biceps Brachii, Brachioradialis
  '프리처컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Brachialis/BBPreacherCurl "Seat should be adjusted to allow armpit to rest near top of pad"
      (
        ko: '겨드랑이가 패드 위쪽에 오게 좌석을 맞춘다',
        en: 'Adjust the seat so your armpits rest near the top of the pad',
        basis: Basis.source,
      ),
      // 🟩 exrx:Brachialis/BBPreacherCurl "Back of upper arm should remain on pad throughout movement"
      (
        ko: '위팔 뒤쪽을 패드에 붙인 채',
        en: 'Keep the backs of your upper arms on the pad',
        basis: Basis.source,
      ),
      // 🟩 exrx:Brachialis/BBPreacherCurl "Raise bar until forearms are vertical"
      (
        ko: '팔뚝이 수직이 될 때까지 든다',
        en: 'Curl until your forearms are vertical',
        basis: Basis.source,
      ),
      // 🟩 exrx:Brachialis/BBPreacherCurl "Lower barbell until arms are fully extended"
      (
        ko: '팔이 다 펴질 때까지 내린다',
        en: 'Lower until your arms are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Brachialis/BBPreacherCurl "Back of upper arm should remain on pad"
      (
        ko: '위팔이 패드에서 뜬다',
        en: 'Upper arms lifting off the pad',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '아래에서 무게를 툭 떨어뜨린다',
        en: 'Dropping the weight at the bottom',
        basis: Basis.none,
      ),
    ],
  ),
  // 케이블컬 (Cable Curl)
  // 근육 🟩 주동 ← ExRx Target: Biceps Brachii
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis
  '케이블컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Biceps/CBCurl "Grasp low pulley cable bar with shoulder width underhand grip"
      (
        ko: '낮은 도르래 가까이 서서 어깨너비 언더그립',
        en: 'Stand close to the low pulley; underhand grip, shoulder width',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/CBCurl "With elbows to side, raise bar until forearms are vertical"
      (
        ko: '팔꿈치를 옆구리에 둔 채 팔뚝이 수직이 될 때까지 든다',
        en: 'Elbows at your sides, curl until your forearms are vertical',
        basis: Basis.source,
      ),
      // 🟩 exrx:Biceps/CBCurl "Lower until arms are fully extended"
      (
        ko: '팔이 다 펴질 때까지 내린다',
        en: 'Lower until your arms are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 ← ace:322 "Keep the elbows in close to the sides through the movement"
      (
        ko: '팔꿈치가 옆구리에서 떨어진다',
        en: 'Elbows leaving your sides',
        basis: Basis.adapted,
      ),
      // 🟦
      (ko: '몸을 뒤로 젖혀 당긴다', en: 'Leaning back to pull', basis: Basis.none),
    ],
  ),
  // 트라이셉스 익스텐션 (Triceps Extension)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: None
  '트라이셉스 익스텐션': Move(
    primary: [...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/DBTriExt "Position one dumbbell over head with both hands"
      (
        ko: '덤벨 하나를 두 손으로 머리 위에 든다',
        en: 'Hold one dumbbell overhead with both hands',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/DBTriExt "With elbows over head, lower forearm behind upper arm by flexing elbows"
      (
        ko: '팔꿈치는 머리 위에 두고 팔뚝만 뒤로 내린다',
        en: 'Keep the elbows overhead; lower the forearms behind',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/DBTriExt "Position wrists closer together to keep elbows from pointing out too much"
      (
        ko: '손목을 모아 팔꿈치가 너무 벌어지지 않게',
        en: 'Keep your wrists close so the elbows don\'t flare too much',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/DBTriExt "Raise dumbbell over head by extending elbows"
      (
        ko: '팔꿈치를 펴 들어 올린다',
        en: 'Extend the elbows to raise it',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:74 "without moving your upper arms"
      (ko: '위팔이 움직인다', en: 'Moving the upper arms', basis: Basis.source),
      // 🟩 ace:74 "Be sure to avoid making contact with the back of your head"
      (
        ko: '덤벨이 뒷머리에 닿는다',
        en: 'Hitting the back of your head',
        basis: Basis.source,
      ),
    ],
  ),
  // 케이블 푸시다운 (Cable Pushdown)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: None
  '케이블 푸시다운': Move(
    primary: [...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/CBPushdown "Position elbows to side"
      (
        ko: '높은 도르래를 보고 서서 팔꿈치를 옆구리에',
        en: 'Face the high pulley with your elbows at your sides',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/CBPushdown "Extend arms down"
      (
        ko: '팔을 끝까지 펴 내린다',
        en: 'Push down until your arms are straight',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/CBPushdown "Return until forearm is close to upper arm"
      (
        ko: '팔뚝이 위팔 가까이 올 때까지 되돌린다',
        en: 'Return until your forearm is close to your upper arm',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/CBPushdown "Stay close to cable to provide resistance at top of motion"
      (ko: '케이블 가까이 선다', en: 'Stand close to the cable', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 ace:185 "with your elbows right next to your side"
      (
        ko: '팔꿈치가 옆구리에서 떨어진다',
        en: 'Elbows drifting away from your sides',
        basis: Basis.source,
      ),
      // 🟩 ace:185 "keeping your torso aligned vertically with the floor"
      (
        ko: '상체를 숙여 체중으로 누른다',
        en: 'Leaning over to push with bodyweight',
        basis: Basis.source,
      ),
    ],
  ),
  // 딥스 (Dips)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: Deltoid, Anterior, Pectoralis Major, Sternal, Pectoralis Major, Clavicular, Pectoralis Minor, Rhomboids, Levator Scapulae, Latissimus Dorsi, Coracobrachialis
  '딥스': Move(
    primary: [...tricepsHeads],
    secondary: [Muscle.frontDelts, Muscle.chest, Muscle.upperBack, Muscle.lats],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/BWTriDip "Mount shoulder width dip bar, arms straight with shoulders above hands"
      (
        ko: '어깨너비 바에서 팔을 펴고 어깨를 손 위에',
        en: 'On shoulder-width bars, arms straight, shoulders above hands',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/BWTriDip "Keep hips straight"
      (ko: '엉덩이를 곧게 편다', en: 'Keep your hips straight', basis: Basis.source),
      // 🟩 exrx:Triceps/BWTriDip "Lower body until slight stretch is felt in shoulders"
      (
        ko: '어깨가 살짝 늘어나는 곳까지 내려간다',
        en: 'Lower until you feel a slight stretch in the shoulders',
        basis: Basis.source,
      ),
      // 🟩 exrx:PectoralSternal/BWChestDip "allowing elbows to flare out to sides"
      (
        ko: '가슴을 더 쓰려면 넓은 바에서 팔꿈치를 벌린다(체스트 딥)',
        en: 'For more chest, use wide bars and let the elbows flare (chest dip)',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Triceps/BWTriDip "Lower body until slight stretch is felt in shoulders"
      (
        ko: '가볍게 늘어나는 느낌을 지나 깊이 내려간다',
        en: 'Dropping deeper than a slight stretch',
        basis: Basis.source,
      ),
      // 🟦
      (ko: '바닥에서 튕겨 올라온다', en: 'Bouncing out of the bottom', basis: Basis.none),
    ],
  ),
  // 킥백 (Kickback)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: None
  '킥백': Move(
    primary: [...tricepsHeads],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/DBKickback "Position upper arm parallel to floor"
      (
        ko: '벤치에 한 손을 짚고 위팔을 바닥과 평행하게',
        en: 'Support yourself on a bench; upper arm parallel to the floor',
        basis: Basis.source,
      ),
      // 🟩 ace:55 "Your upper arm should remain stationary next to your torso"
      (
        ko: '위팔은 몸통 옆에 고정',
        en: 'Keep the upper arm still, next to your torso',
        basis: Basis.source,
      ),
      // 🟩 exrx:Triceps/DBKickback "Extend arm until it is straight"
      (
        ko: '팔이 곧게 펴질 때까지 뒤로 편다',
        en: 'Extend until the arm is straight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:55 "Avoid any arching (sagging) in your low back or any rotation in your torso"
      (
        ko: '허리가 처지거나 몸통이 돌아간다',
        en: 'Sagging low back or rotating torso',
        basis: Basis.source,
      ),
      // 🟦
      (ko: '무게를 휘둘러 올린다', en: 'Swinging the weight up', basis: Basis.none),
    ],
  ),
  // 플랭크 (Plank)
  // 근육 🟩 주동 ← ExRx Target: Rectus Abdominis
  //      🟩 보조 ← ExRx Synergists:
  '플랭크': Move(
    primary: [Muscle.abs],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:RectusAbdominis/BWFrontPlank "elbows under shoulders"
      (
        ko: '팔꿈치를 어깨 바로 아래에',
        en: 'Elbows directly under your shoulders',
        basis: Basis.source,
      ),
      // 🟩 exrx:RectusAbdominis/BWFrontPlank "Raise body upward by straightening body in straight line"
      (
        ko: '몸을 일직선으로 들어 유지한다',
        en: 'Lift your body into a straight line and hold',
        basis: Basis.source,
      ),
      // 🟩 ace:32 "Continue to breath while holding this position"
      (ko: '숨은 계속 쉰다', en: 'Keep breathing', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 ace:32 "Avoid any arching (sagging) in your low back, hiking (upwards) in your hips"
      (
        ko: '허리가 처지거나 엉덩이가 솟는다',
        en: 'Sagging low back or hips hiking up',
        basis: Basis.source,
      ),
      // 🟩 ace:32 "Avoid shrugging your shoulder"
      (ko: '어깨를 으쓱한다', en: 'Shrugging the shoulders', basis: Basis.source),
    ],
  ),
  // 사이드 플랭크 (Side Plank)
  // 근육 🟩 주동 ← ExRx Target: Obliques
  //      🟩 보조 ← ExRx Synergists:
  '사이드 플랭크': Move(
    primary: [Muscle.obliques],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Obliques/BWSidePlank "Place forearm on mat under shoulder perpendicular to body"
      (
        ko: '옆으로 누워 팔뚝을 어깨 아래에 몸과 직각으로',
        en: 'Lie on your side, forearm under the shoulder, perpendicular to the body',
        basis: Basis.source,
      ),
      // 🟩 exrx:Obliques/BWSidePlank "Place upper leg directly on top of lower leg"
      (
        ko: '위 다리를 아래 다리 위에 포갠다',
        en: 'Stack your top leg on the bottom leg',
        basis: Basis.source,
      ),
      // 🟩 exrx:Obliques/BWSidePlank "Raise body upward by straightening waist"
      (
        ko: '허리를 펴 몸을 들고 단단히 유지한다',
        en: 'Lift by straightening your waist and hold the body rigid',
        basis: Basis.source,
      ),
      // 🟩 ace:303 "Squeeze the muscles of the stomach and glutes"
      (
        ko: '배와 엉덩이에 힘을 준다',
        en: 'Squeeze your stomach and glutes',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:303 "keep the body in a straight line from head to heels"
      (ko: '엉덩이가 처진다', en: 'Hips sagging', basis: Basis.source),
      // 🟩 exrx:Obliques/BWSidePlank "Repeat with opposite side"
      (ko: '한쪽만 한다', en: 'Only training one side', basis: Basis.source),
    ],
  ),
  // 크런치 (Crunch)
  // 근육 🟩 주동 ← ExRx Target: Rectus Abdominis
  //      🟩 보조 ← ExRx Synergists: Obliques
  '크런치': Move(
    primary: [Muscle.abs],
    secondary: [Muscle.obliques],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:52 "Place your hands behind your head"
      (
        ko: '무릎을 굽히고 누워 손은 머리 뒤에',
        en: 'Lie with knees bent, hands behind your head',
        basis: Basis.source,
      ),
      // 🟩 ace:52 "pulling your rib cage towards your pelvis"
      (
        ko: '갈비뼈를 골반 쪽으로 당기듯 상체를 만다',
        en: 'Curl up by pulling your ribs toward your pelvis',
        basis: Basis.source,
      ),
      // 🟩 ace:52 "Continue curling up until your upper back is lifted off the mat"
      (
        ko: '허리는 바닥에 붙이고 등 윗부분만 든다',
        en: 'Keep your low back down; lift only the upper back',
        basis: Basis.source,
      ),
      // 🟩 exrx:RectusAbdominis/BWCrunch "Certain individuals may need to keep their neck in neutral position"
      (
        ko: '사람에 따라 턱과 가슴 사이에 공간을 두고 목을 중립으로',
        en: 'Some people should keep a neutral neck with space between chin and chest',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:52 "the neck stays relaxed"
      (ko: '목에 힘을 준다', en: 'Straining the neck', basis: Basis.source),
      // 🟩 ace:52 "Your feet, tailbone and lower back should remain in contact with the mat at all times"
      (ko: '허리가 바닥에서 뜬다', en: 'Low back leaving the mat', basis: Basis.source),
    ],
  ),
  // 싯업 (Sit Up)
  // 근육 🟩 주동 ← ExRx Target: Rectus Abdominis
  //      🟩 보조 ← ExRx Synergists: Iliopsoas, Tensor Fasciae Latae, Rectus Femoris, Sartorius, Obliques
  '싯업': Move(
    primary: [Muscle.abs],
    secondary: [Muscle.hipFlexors, Muscle.quads, Muscle.obliques],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:RectusAbdominis/BWSitUp "Lie supine on floor or bench with hips bent"
      (
        ko: '발을 받침에 걸고 엉덩이를 굽힌 채 눕는다',
        en: 'Hook your feet and lie with your hips bent',
        basis: Basis.source,
      ),
      // 🟩 exrx:RectusAbdominis/BWSitUp "Raise torso from bench by bending waist and hips"
      (
        ko: '허리와 엉덩이를 굽혀 상체를 든다',
        en: 'Raise your torso by bending at the waist and hips',
        basis: Basis.source,
      ),
      // 🟩 exrx:RectusAbdominis/BWSitUp "Return until back of shoulders contact incline board"
      (
        ko: '어깨 뒤가 바닥에 닿을 때까지 내려온다',
        en: 'Lower until the backs of your shoulders touch down',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:RectusAbdominis/BWSitUp "If upper back does not come completely down at end of movement, abdominal muscles may only be isometrically involved"
      (
        ko: '등 윗부분을 끝까지 내리지 않는다 — 복근이 버티기만 한다',
        en: 'Not lowering the upper back fully — the abs then only hold',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '손으로 목을 당긴다',
        en: 'Yanking the neck with your hands',
        basis: Basis.none,
      ),
    ],
  ),
  // 행잉 레그레이즈 (Hanging Leg Raise)
  // 근육 🟩 주동 ← ExRx Target: Iliopsoas
  //      🟩 보조 ← ExRx Synergists: Tensor Fasciae Latae, Pectineus, Sartorius, Adductor Longus, Adductor Brevis
  // ExRx 기준 주동근은 고관절 굴곡근이다. 복근은 허리를 말아 올릴 때만 동적으로 일한다.
  '행잉 레그레이즈': Move(
    primary: [Muscle.hipFlexors],
    secondary: [Muscle.adductors],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "Grasp and hang from high bar with slightly wider than shoulder width overhand grip"
      (
        ko: '어깨너비보다 조금 넓게 바에 매달린다',
        en: 'Hang from a high bar, grip slightly wider than shoulders',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "until hips are completely flexed or knees are well above hips"
      (
        ko: '무릎이 엉덩이보다 충분히 올라올 때까지 다리를 든다',
        en: 'Raise your legs until your knees are well above your hips',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "Return until hips and knees are extended downward"
      (
        ko: '엉덩이·무릎이 펴질 때까지 내린다',
        en: 'Lower until hips and knees are straight',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "Rectus Abdominis and Obliques only contract dynamically if actual waist flexion occurs"
      (
        ko: '복근을 쓰려면 골반까지 말아 올린다',
        en: 'To work the abs, curl the pelvis up too',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '몸을 흔들어 반동으로 든다',
        en: 'Swinging to kick the legs up',
        basis: Basis.none,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "With no waist flexion, Rectus Abdominis and External Oblique will only act to stabilize"
      (
        ko: '다리만 올리며 복근 운동이라고 여긴다',
        en: 'Treating hip-only lifting as an ab exercise',
        basis: Basis.source,
      ),
    ],
  ),
  // 러시안 트위스트 (Russian Twist)
  // 근육 🟩 주동 ← ExRx Target: Obliques
  //      🟩 보조 ← ExRx Synergists: Hip External Rotators, Psoas major, Quadratus lumborum, Iliocastalis lumborum, Iliocastalis thoracis
  // 근거는 ExRx·ACE 의 짐볼 러시안 트위스트와 ACE V-twist(BOSU 위) 다. 바닥에서 하는 흔한 러시안 트위스트와 같은 근육을 쓴다고 본 것은 🟦.
  '러시안 트위스트': Move(
    primary: [Muscle.obliques],
    primaryInterp: true,
    secondaryInterp: true,
    secondary: [Muscle.hipFlexors, Muscle.lowerBack],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:305 "While maintaining a straight back"
      (
        ko: '상체를 뒤로 기울이고 등을 곧게',
        en: 'Lean back with a straight back',
        basis: Basis.source,
      ),
      // 🟩 ace:305 "rotate the shoulders from side to side"
      (
        ko: '어깨를 좌우로 돌린다',
        en: 'Rotate your shoulders side to side',
        basis: Basis.source,
      ),
      // 🟦 ← exrx:Obliques/DBRussianTwistBall "keeping arms straight and perpendicular to torso throughout movement"
      (
        ko: '팔은 몸통과 직각으로 편 채 몸통째 돈다',
        en: 'Keep the arms straight and perpendicular to the torso as you turn',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '팔만 흔들고 몸통은 안 돈다',
        en: 'Swinging only the arms without turning the torso',
        basis: Basis.none,
      ),
      // 🟦 ← ace:305 "While maintaining a straight back"
      (ko: '등이 둥글게 말린다', en: 'Rounding the back', basis: Basis.adapted),
    ],
  ),
  // 케이블 레터럴 레이즈 (Cable Lateral Raise)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Lateral
  //      🟩 보조 ← ExRx Synergists: Deltoid, Anterior, Supraspinatus, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations
  '케이블 레터럴 레이즈': Move(
    primary: [Muscle.sideDelts],
    secondary: [Muscle.frontDelts, Muscle.upperBack],
    gear: ['cable'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '케이블 레터럴 레이즈',
      'Cable Lateral Raise',
      'ケーブルサイドレイズ',
      '绳索侧平举',
      '繩索側平舉',
      'Elevación Lateral en Polea',
      'Nâng Cáp Ngang Vai',
      'เคเบิลไซด์เรส',
    ),
    cues: [
      // 🟩 exrx:DeltoidLateral/CBLateralRaise "grasp left stirrup with right hand and right stirrup with left hand"
      (
        ko: '낮은 도르래 두 개 사이에 서서 반대편 손잡이를 엇갈려 잡는다',
        en: 'Stand between two low pulleys holding the opposite handles',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidLateral/CBLateralRaise "Maintain fixed slightly bent elbow position throughout exercise"
      (
        ko: '팔꿈치를 살짝 굽혀 고정한다',
        en: 'Keep a slight, fixed bend in the elbows',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidLateral/CBLateralRaise "raise arms to sides until elbows are shoulder height"
      (
        ko: '팔꿈치가 어깨 높이가 될 때까지 옆으로 든다',
        en: 'Raise to the sides until your elbows reach shoulder height',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidLateral/CBLateralRaise "Stirrup is raised by shoulder abduction, not external rotation"
      (
        ko: '팔을 바깥으로 돌려 든다',
        en: 'Rotating the arms outward to lift',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '몸을 기울여 반동을 쓴다',
        en: 'Leaning to swing the weight',
        basis: Basis.none,
      ),
    ],
  ),
  // 리버스 펙덱 (Reverse Pec Deck)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Posterior
  //      🟩 보조 ← ExRx Synergists: Infraspinatus, Teres Minor, Deltoid, Lateral, Trapezius, Middle, Trapezius, Lower, Rhomboids
  '리버스 펙덱': Move(
    primary: [Muscle.rearDelts],
    secondary: [
      Muscle.upperBack,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.sideDelts,
    ],
    gear: ['machine'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '리버스 펙덱',
      'Reverse Pec Deck',
      'リバースペックデック',
      '反向蝴蝶机',
      '反向蝴蝶機',
      'Contractora Inversa',
      'Ép Vai Sau Máy',
      'รีเวิร์สเพคเด็ค',
    ),
    aliases: [
      '리버스 펙덱',
      '리어델트 머신',
      '리버스 플라이 머신',
      'Life Fitness Insignia Pectoral Fly / Rear Deltoid',
      'Technogym Selection 900 Reverse Fly',
      'DRAX Pure Plate Bent Over Lateral Raise',
      'reverse fly',
      'rear delt fly',
    ],
    cues: [
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Grasp parallel handles with thumbs up at shoulder height"
      (
        ko: '가슴을 패드에 대고 손잡이를 어깨 높이에서 잡는다',
        en: 'Chest on the pad, handles at shoulder height',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Keeping elbows pointed high, pull handles apart and to rear"
      (
        ko: '팔꿈치를 높게 유지한 채 손잡이를 뒤로 벌린다',
        en: 'Keeping your elbows high, pull the handles apart and back',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "until elbows are just behind back"
      (
        ko: '팔꿈치가 등 바로 뒤에 오면 되돌린다',
        en: 'Return once your elbows are just behind your back',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Seat height and grip should be adjusted to keep arms at transverse plane of shoulders"
      (
        ko: '팔이 어깨 높이에 오게 좌석과 그립을 맞춘다',
        en: 'Set seat and grip so your arms stay at shoulder level',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Natural tendency is for shoulders to point down which places greater emphasis on lateral deltoid"
      (
        ko: '팔꿈치가 아래로 떨어진다 — 옆어깨·광배가 대신 쓰인다',
        en: 'Elbows dropping, shifting the work to side delts and lats',
        basis: Basis.source,
      ),
      // 🟦
      (ko: '반동으로 튕긴다', en: 'Jerking with momentum', basis: Basis.none),
    ],
  ),
  // 페이스 풀 (Face Pull)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Posterior
  //      🟩 보조 ← ExRx Synergists: Infraspinatus, Teres Minor, Deltoid, Lateral, Trapezius, Middle, Trapezius, Lower, Rhomboids, Brachialis, Brachioradialis
  // 근거 페이지의 이름은 "Cable Standing Rear Delt Row (with rope)" 이고 로프를 윗가슴이나 목으로 당긴다. 흔히 말하는 페이스 풀과 같은 동작으로 본 것은 🟦.
  '페이스 풀': Move(
    primary: [Muscle.rearDelts],
    secondary: [
      Muscle.upperBack,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.sideDelts,
      Muscle.biceps,
      Muscle.forearms,
    ],
    gear: ['cable'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '페이스 풀',
      'Face Pull',
      'フェイスプル',
      '面拉',
      '面拉',
      'Face Pull',
      'Kéo Cáp Về Mặt',
      'เฟซพูล',
    ),
    aliases: ['facepull'],
    cues: [
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "Step back with one foot so arms and shoulders are positioned straight forward with cable taut"
      (
        ko: '높은 도르래 로프를 잡고 한 발 물러서 팔을 앞으로 편다',
        en: 'Grab the rope from a high pulley and step back so the arms are straight in front',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "keeping elbows at shoulder height"
      (
        ko: '팔꿈치를 바깥으로, 어깨 높이로',
        en: 'Point the elbows out and keep them at shoulder height',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "Keep upper arms perpendicular to trunk"
      (
        ko: '위팔을 몸통과 직각으로 유지하며 당긴다',
        en: 'Keep your upper arms perpendicular to your trunk as you pull',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "if upper arm travels closer than perpendicular to trunk"
      (
        ko: '위팔이 몸통 쪽으로 내려와 광배가 끼어든다',
        en: 'Upper arms dropping toward the torso, bringing in the lats',
        basis: Basis.source,
      ),
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "if torso is positioned forward beyond vertical"
      (
        ko: '상체가 앞으로 숙여진다',
        en: 'Leaning the torso forward',
        basis: Basis.source,
      ),
    ],
  ),
  // 덤벨 슈러그 (Dumbbell Shrug)
  // 근육 🟩 주동 ← ExRx Target: Trapezius, Upper
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Levator Scapulae
  '덤벨 슈러그': Move(
    primary: [Muscle.traps],
    secondary: [Muscle.upperBack],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '덤벨 슈러그',
      'Dumbbell Shrug',
      'ダンベルシュラッグ',
      '哑铃耸肩',
      '啞鈴聳肩',
      'Encogimientos con Mancuernas',
      'Nhún Vai Tạ Đơn',
      'ดัมเบลชรัก',
    ),
    cues: [
      // 🟩 exrx:TrapeziusUpper/DBShrug "Stand holding dumbbells to sides"
      (
        ko: '덤벨을 옆에 들고 선다',
        en: 'Stand holding dumbbells at your sides',
        basis: Basis.source,
      ),
      // 🟩 exrx:TrapeziusUpper/DBShrug "Elevate shoulders as high as possible"
      (
        ko: '어깨를 최대한 높이 올린다',
        en: 'Raise your shoulders as high as possible',
        basis: Basis.source,
      ),
      // 🟩 ace:75 "gently lower the dumbbells back towards your starting position"
      (ko: '천천히 내린다', en: 'Lower slowly', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 ace:75 "avoiding any shoulder rotation or elbow flexion"
      (
        ko: '어깨를 돌리거나 팔꿈치를 굽힌다',
        en: 'Rolling the shoulders or bending the elbows',
        basis: Basis.source,
      ),
      // 🟩 ace:75 "no arching in your low back"
      (ko: '허리를 젖힌다', en: 'Arching the low back', basis: Basis.source),
    ],
  ),
  // 파머스 워크 (Farmer's Walk)
  // 근육 출처: exrx:Kettlebell/KBFarmersWalk
  // 🟦 주동 ← ExRx 설명 문장 "particularly of traps and grip" (근육 목록은 없다, ACE 359 는 "Full Body/Integrated" 로만 적었다).
  // 안정근(허리·옆구리·엉덩이)은 ExRx 관절 동작(척추 신전·측굴, 고관절 외전 — 정적)을 옮긴 🟦.
  '파머스 워크': Move(
    primary: [Muscle.traps, Muscle.forearms],
    primaryInterp: true,
    gear: ['kettlebell', 'dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '파머스 워크',
      'Farmer\'s Walk',
      'ファーマーズウォーク',
      '农夫行走',
      '農夫行走',
      'Paseo del Granjero',
      'Đi Bộ Xách Tạ',
      'ฟาร์มเมอร์วอล์ก',
    ),
    aliases: ['farmers carry', '파머스캐리'],
    cues: [
      // 🟩 exrx:Kettlebell/KBFarmersWalk "Deadlift kettlebells from floor using legs"
      (
        ko: '다리 힘으로 바닥에서 들어 올린다',
        en: 'Lift them off the floor with your legs',
        basis: Basis.source,
      ),
      // 🟩 ace:359 "Hold a dumbbell in each hand with a tight, firm grip"
      (
        ko: '팔은 옆으로 곧게 두고 단단히 쥔다',
        en: 'Arms straight at your sides, grip tight',
        basis: Basis.source,
      ),
      // 🟩 ace:359 "Keep the back straight and walk"
      (
        ko: '등을 곧게 세우고 걷는다',
        en: 'Keep your back straight as you walk',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 ← exrx:Kettlebell/KBFarmersWalk "Deadlift kettlebells from floor using legs"
      (
        ko: '허리를 굽혀 바닥에서 든다',
        en: 'Picking the weights up with a rounded back',
        basis: Basis.adapted,
      ),
      // 🟦
      (ko: '몸이 한쪽으로 기운다', en: 'Leaning to one side', basis: Basis.none),
    ],
  ),
  // 리스트 컬 (Wrist Curl)
  // 근육 🟩 주동 ← ExRx Target: Wrist Flexors
  //      🟩 보조 ← ExRx Synergists: None
  // 내릴 때 바를 손끝까지 굴리는 방식을 ExRx 는 설명에 넣었고, ACE 는 손목 부상·떨어뜨릴 위험이 커진다고 적었다 — 출처가 갈린다.
  '리스트 컬': Move(
    primary: [Muscle.forearms],
    gear: ['barbell', 'dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '리스트 컬',
      'Wrist Curl',
      'リストカール',
      '腕弯举',
      '腕彎舉',
      'Curl de Muñeca',
      'Cuốn Cổ Tay',
      'ริสต์เคิร์ล',
    ),
    cues: [
      // 🟩 exrx:WristFlexors/BBWristCurl "Rest forearms on thighs with wrists just beyond knees"
      (
        ko: '앉아서 팔뚝을 허벅지에 올리고 손목은 무릎 밖으로',
        en: 'Sit with forearms on your thighs, wrists just past your knees',
        basis: Basis.source,
      ),
      // 🟩 exrx:WristFlexors/BBWristCurl "underhand grip"
      (ko: '언더그립으로 잡는다', en: 'Use an underhand grip', basis: Basis.source),
      // 🟩 exrx:WristFlexors/BBWristCurl "pointing knuckles up as high as possible"
      (
        ko: '손목만 굽혀 들어 올린다',
        en: 'Curl up using only the wrists',
        basis: Basis.source,
      ),
      // 🟩 exrx:WristFlexors/BBWristCurl "Keep elbows approximately wrist height"
      (
        ko: '팔꿈치는 손목 높이 정도로',
        en: 'Keep elbows about wrist height',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:30 "extending your arms or leaning forward / backward"
      (
        ko: '몸을 앞뒤로 흔들거나 팔을 편다',
        en: 'Rocking the body or straightening the arms',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '무거워서 가동 범위를 반만 쓴다',
        en: 'Cutting the range short because the weight is too heavy',
        basis: Basis.none,
      ),
    ],
  ),
  // 백 익스텐션 (Back Extension)
  // 근육 🟩 주동 ← ExRx Target: Erector Spinae, Hamstrings
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Hamstrings, Adductor Magnus, Erector Spinae, Gluteus Maximus, Adductor Magnus
  '백 익스텐션': Move(
    primary: [Muscle.lowerBack, Muscle.hamstrings],
    secondary: [Muscle.glutes, Muscle.adductors],
    // 🟩 ExRx: "Position thighs prone on padding" — 하이퍼익스텐션 벤치다.
    gear: ['machine'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '백 익스텐션',
      'Back Extension',
      'バックエクステンション',
      '山羊挺身',
      '山羊挺身',
      'Extensión Lumbar',
      'Duỗi Lưng',
      'แบ็กเอ็กซ์เทนชัน',
    ),
    aliases: ['hyperextension', '하이퍼익스텐션'],
    cues: [
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Hook heels on platform lip or under padded brace"
      (
        ko: '허벅지를 패드에 대고 뒤꿈치를 받침에 건다',
        en: 'Thighs on the pad, heels hooked under the brace',
        basis: Basis.source,
      ),
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "abdomen should not press on top side of pad when upper body is lowered"
      (
        ko: '내려갈 때 배가 패드에 눌리지 않을 높이로 맞춘다',
        en: 'Set the pad so your abdomen does not press on it as you lower',
        basis: Basis.source,
      ),
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Raise upper body until hips and waist are extended"
      (
        ko: '엉덩이와 허리가 펴질 때까지 상체를 든다',
        en: 'Raise your upper body until hips and waist are straight',
        basis: Basis.source,
      ),
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Begin with arms in low position and gradually position arms in higher position"
      (
        ko: '팔은 낮은 위치에서 시작해 점차 올린다',
        en: 'Start with arms low and move them higher gradually',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Do not lower weight beyond mild stretch throughout hamstrings and low back"
      (
        ko: '가볍게 늘어나는 느낌을 넘어 깊이 내려간다',
        en: 'Lowering past a mild stretch',
        basis: Basis.source,
      ),
      // 🟦
      (ko: '위에서 과하게 젖힌다', en: 'Over-arching at the top', basis: Basis.none),
    ],
  ),
  // 슈퍼맨 (Superman)
  // 근육 출처: ace:9
  // 🟩 주동 ← ACE 주동근: 앞·옆 삼각근, 척추기립근, 둔근, 승모근.
  // 🟦 보조 ← 넷 중 어깨·승모를 보조로 내린 것은 해석이다.
  '슈퍼맨': Move(
    primary: [Muscle.lowerBack, Muscle.glutes],
    secondary: [Muscle.frontDelts, Muscle.sideDelts, Muscle.traps],
    secondaryInterp: true,
    gear: ['bodyweight'],
    sites: ['ACE'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '슈퍼맨',
      'Superman',
      'スーパーマン',
      '超人式',
      '超人式',
      'Superman',
      'Siêu Nhân',
      'ซูเปอร์แมน',
    ),
    cues: [
      // 🟩 ace:9 "arms extended overhead with palms facing each other"
      (
        ko: '엎드려 팔을 머리 위로 뻗는다',
        en: 'Lie face down with your arms extended overhead',
        basis: Basis.source,
      ),
      // 🟩 ace:9 "contract your abdominal and core muscles to stabilize your spine"
      (
        ko: '배에 힘을 줘 척추를 고정한다',
        en: 'Brace to stabilize your spine',
        basis: Basis.source,
      ),
      // 🟩 ace:9 "a few inches off the floor while simultaneously raising both arms"
      (
        ko: '팔과 다리를 바닥에서 조금만 동시에 든다',
        en: 'Lift arms and legs a little off the floor at the same time',
        basis: Basis.source,
      ),
      // 🟩 ace:9 "Hold this position briefly"
      (ko: '잠깐 멈췄다가 내린다', en: 'Hold briefly, then lower', basis: Basis.source),
    ],
    mistakes: [
      // 🟩 ace:9 "avoiding any arching in your back or raising of your head"
      (
        ko: '허리를 과하게 꺾거나 머리를 든다',
        en: 'Over-arching the back or lifting the head',
        basis: Basis.source,
      ),
      // 🟩 ace:9 "avoiding any rotation in each"
      (
        ko: '팔다리가 돌아간다',
        en: 'Letting the arms or legs rotate',
        basis: Basis.source,
      ),
    ],
  ),
  // 바이시클 크런치 (Bicycle Crunch)
  // 근육 출처: ace:241
  // ACE 주동근: 복사근, 복직근, 복횡근.
  '바이시클 크런치': Move(
    primary: [Muscle.obliques, Muscle.abs],
    gear: ['bodyweight'],
    sites: ['ACE'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '바이시클 크런치',
      'Bicycle Crunch',
      'バイシクルクランチ',
      '单车卷腹',
      '單車捲腹',
      'Abdominales Bicicleta',
      'Gập Bụng Đạp Xe',
      'ไบซิเคิลครันช์',
    ),
    cues: [
      // 🟩 ace:241 "Maintain a 90-degree bend at the knee"
      (
        ko: '누워서 무릎을 90°로 굽혀 든다',
        en: 'Lie back with knees lifted and bent to 90°',
        basis: Basis.source,
      ),
      // 🟩 ace:241 "Drive your right knee towards your chest"
      (
        ko: '한쪽 무릎을 가슴 쪽으로 당기며 반대 다리는 편다',
        en: 'Drive one knee toward your chest while extending the other leg',
        basis: Basis.source,
      ),
      // 🟩 ace:241 "rotating your trunk slowly to drive your left elbow towards your right knee"
      (
        ko: '반대쪽 팔꿈치가 그 무릎으로 가게 몸통을 돌린다',
        en: 'Rotate so the opposite elbow moves toward that knee',
        basis: Basis.source,
      ),
      // 🟩 ace:241 "This movement will press your low back into the floor"
      (
        ko: '허리는 바닥에 눌러 둔다',
        en: 'Keep your low back pressed into the mat',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '몸통은 안 돌고 팔꿈치만 빠르게 휘두른다',
        en: 'Flapping the elbows quickly instead of rotating the trunk',
        basis: Basis.none,
      ),
      // 🟦
      (ko: '손으로 목을 당긴다', en: 'Pulling on the neck', basis: Basis.none),
    ],
  ),
  // 버티컬 레그레이즈 (Vertical Leg Raise)
  // 근육 🟩 주동 ← ExRx Target: Iliopsoas
  //      🟩 보조 ← ExRx Synergists: Tensor Fasciae Latae, Pectineus, Sartorius, Adductor Longus, Adductor Brevis
  // ExRx 기준 주동근은 고관절 굴곡근이다. 복근은 허리를 말아 올릴 때만 동적으로 일한다.
  '버티컬 레그레이즈': Move(
    primary: [Muscle.hipFlexors],
    secondary: [Muscle.adductors],
    // 🟩 ExRx: "back on vertical pad" — 전용 기구(캡틴스 체어)다.
    gear: ['machine'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '버티컬 레그레이즈',
      'Vertical Leg Raise',
      'バーティカルレッグレイズ',
      '直角架举腿',
      '直角架舉腿',
      'Elevación de Piernas en Paralelas',
      'Nâng Chân Ghế Tựa',
      'เวอร์ติคัลเลกเรส',
    ),
    aliases: ['captain\'s chair', '캡틴스체어'],
    cues: [
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "Position forearms on padded parallel bars with hands on handles, and back on vertical pad"
      (
        ko: '팔뚝을 평행 패드에 올리고 등을 수직 패드에 댄다',
        en: 'Forearms on the padded bars, back against the vertical pad',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "until hips are completely flexed or knees are well above hips"
      (
        ko: '무릎이 엉덩이보다 충분히 올라올 때까지 다리를 든다',
        en: 'Raise your legs until your knees are well above your hips',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "Return until hips and knees are extended"
      (
        ko: '엉덩이·무릎이 펴질 때까지 내린다',
        en: 'Lower until hips and knees are straight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "With no waist flexion, Rectus Abdominis and External Oblique will only act to stabilize"
      (
        ko: '다리만 올리며 복근 운동이라고 여긴다',
        en: 'Treating hip-only lifting as an ab exercise',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '다리를 흔들어 반동을 쓴다',
        en: 'Swinging the legs for momentum',
        basis: Basis.none,
      ),
    ],
  ),
  // 힙 어덕션 (Hip Adduction)
  // 근육 🟩 주동 ← ExRx Target: Adductors, Hip
  //      🟩 보조 ← ExRx Synergists: Pectineus, Gracilis
  '힙 어덕션': Move(
    primary: [Muscle.adductors],
    gear: ['machine'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '힙 어덕션',
      'Hip Adduction',
      'ヒップアダクション',
      '髋内收',
      '髖內收',
      'Aducción de Cadera',
      'Khép Hông Máy',
      'ฮิปแอดดักชัน',
    ),
    aliases: [
      'adductor',
      '어덕터',
      'Matrix Ultra Hip Adductor',
      'Nautilus Impact Adductor',
      'Precor Resolute Inner Thigh',
    ],
    cues: [
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "position legs apart until slight stretch is felt"
      (
        ko: '다리를 벌린 시작 폭은 살짝 늘어나는 곳까지',
        en: 'Set the starting width to a slight stretch',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "Lie back and grasp bars to sides"
      (
        ko: '등을 기대고 손잡이를 잡는다',
        en: 'Lean back and hold the handles',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "Move legs together. Return and repeat"
      (
        ko: '다리를 모은 뒤 되돌린다',
        en: 'Bring your legs together, then return',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "until slight stretch is felt"
      (
        ko: '살짝 늘어나는 느낌보다 넓게 벌려 시작한다',
        en: 'Starting wider than a slight stretch',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '되돌릴 때 무게에 다리가 확 벌어진다',
        en: 'Letting the weight yank your legs open',
        basis: Basis.none,
      ),
    ],
  ),
  // 케이블 힙 어덕션 (Cable Hip Adduction)
  // 근육 🟩 주동 ← ExRx Target: Adductors, Hip
  //      🟩 보조 ← ExRx Synergists: Pectineus, Gracilis, Gluteus Maximus, Lower Fibers
  '케이블 힙 어덕션': Move(
    primary: [Muscle.adductors],
    secondary: [Muscle.glutes],
    gear: ['cable'],
    sites: ['ACE', 'ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '케이블 힙 어덕션',
      'Cable Hip Adduction',
      'ケーブルヒップアダクション',
      '绳索髋内收',
      '繩索髖內收',
      'Aducción de Cadera en Polea',
      'Khép Hông Cáp',
      'เคเบิลฮิปแอดดักชัน',
    ),
    cues: [
      // 🟩 exrx:HipAdductors/CBHipAdduction "Attach cable cuff to near ankle"
      (
        ko: '낮은 도르래 발목 스트랩을 가까운 발에 건다',
        en: 'Attach the low-pulley cuff to your near ankle',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipAdductors/CBHipAdduction "Step out away from stack with wide stance"
      (
        ko: '넓게 서서 지지대를 잡고 먼 발로 선다',
        en: 'Stand wide, hold a support and stand on the far foot',
        basis: Basis.source,
      ),
      // 🟩 exrx:HipAdductors/CBHipAdduction "Move near leg just in front of far leg"
      (
        ko: '가까운 다리를 반대 다리 앞까지 가져온다',
        en: 'Bring the near leg just in front of the other',
        basis: Basis.source,
      ),
      // 🟩 ace:104 "Keep the back straight and the left knee slightly bent"
      (
        ko: '등을 곧게, 딛는 무릎은 살짝 굽힌다',
        en: 'Back straight, standing knee slightly bent',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '몸통을 기울여 다리를 끌어온다',
        en: 'Leaning the torso to drag the leg across',
        basis: Basis.none,
      ),
      // 🟩 ace:104 "slowly lowering the weight"
      (
        ko: '되돌릴 때 무게에 끌려간다',
        en: 'Letting the weight snap the leg back',
        basis: Basis.source,
      ),
    ],
  ),
  // 사이드 라잉 힙 어덕션 (Side-Lying Hip Adduction)
  // 근육 출처: ace:39
  // ACE 주동근: 내전근.
  '사이드 라잉 힙 어덕션': Move(
    primary: [Muscle.adductors],
    gear: ['bodyweight'],
    sites: ['ACE'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '사이드 라잉 힙 어덕션',
      'Side-Lying Hip Adduction',
      'サイドライイングアダクション',
      '侧卧髋内收',
      '側臥髖內收',
      'Aducción de Cadera Tumbado de Lado',
      'Khép Hông Nằm Nghiêng',
      'นอนตะแคงหุบขา',
    ),
    cues: [
      // 🟩 ace:39 "flex (move forward) your lower leg until it lies in front of your upper leg"
      (
        ko: '옆으로 누워 아래 다리를 위 다리 앞으로 옮긴다',
        en: 'Lie on your side and move the bottom leg forward, in front of the top leg',
        basis: Basis.source,
      ),
      // 🟩 ace:39 "gently raise the lower leg off the floor while keeping the knee extended"
      (
        ko: '무릎을 편 채 아래 다리를 들어 올린다',
        en: 'Raise the bottom leg with the knee straight',
        basis: Basis.source,
      ),
      // 🟩 ace:39 "the leg need only rise a few inches off the mat/floor"
      (
        ko: '움직임이 작다 — 조금만 들어도 된다',
        en: 'It\'s a small movement — a little lift is enough',
        basis: Basis.source,
      ),
      // 🟩 ace:39 "The hips should remain vertical to the floor"
      (
        ko: '엉덩이는 바닥과 수직으로',
        en: 'Keep your hips stacked vertically',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 ace:39 "knee of the raised leg should not rotate upward towards the ceiling or downward towards the floor"
      (
        ko: '들어 올리는 다리의 무릎이 위나 아래로 돌아간다',
        en: 'Letting the knee of the raised leg rotate up or down',
        basis: Basis.source,
      ),
      // 🟩 ace:39 "until your hips begin to tilt sideways"
      (
        ko: '엉덩이가 옆으로 기울 만큼 높이 든다',
        en: 'Lifting so high the hips tilt sideways',
        basis: Basis.source,
      ),
    ],
  ),
  // 시티드 카프레이즈 (Seated Calf Raise)
  // 근육 🟩 주동 ← ExRx Target: Soleus
  //      🟩 보조 ← ExRx Synergists: Gastrocnemius
  // 무릎을 굽혀 앉으면 가자미근(soleus)이 주로 일한다(ExRx).
  '시티드 카프레이즈': Move(
    primary: [Muscle.calves],
    gear: ['machine'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '시티드 카프레이즈',
      'Seated Calf Raise',
      'シーテッドカーフレイズ',
      '坐姿提踵',
      '坐姿提踵',
      'Elevación de Talones Sentado',
      'Nhón Bắp Chân Ngồi',
      'ซีทเต็ดคาล์ฟเรส',
    ),
    aliases: [
      'Hammer Strength Plate Loaded Seated Calf Raise',
      'Precor Resolute Seated Calf',
    ],
    cues: [
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Place forefeet on platform with heels extending off"
      (
        ko: '앞발을 발판에, 뒤꿈치는 밖으로',
        en: 'Forefeet on the platform, heels off',
        basis: Basis.source,
      ),
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Position lower thighs under lever pads"
      (
        ko: '허벅지 아래쪽을 패드 밑에 둔다',
        en: 'Lower thighs under the pads',
        basis: Basis.source,
      ),
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Raise heels by extending ankles as high as possible"
      (
        ko: '뒤꿈치를 최대한 높이 든다',
        en: 'Raise your heels as high as possible',
        basis: Basis.source,
      ),
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Lower heels by bending ankles until calves are stretched"
      (
        ko: '종아리가 늘어날 때까지 내린다',
        en: 'Lower until your calves stretch',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦
      (ko: '가동 범위를 반만 쓴다', en: 'Half reps', basis: Basis.none),
      // 🟦
      (ko: '반동으로 튕긴다', en: 'Bouncing', basis: Basis.none),
    ],
  ),
  // 레그프레스 카프레이즈 (Leg Press Calf Raise)
  // 근육 🟩 주동 ← ExRx Target: Gastrocnemius
  //      🟩 보조 ← ExRx Synergists: Soleus
  '레그프레스 카프레이즈': Move(
    primary: [Muscle.calves],
    gear: ['machine'],
    sites: ['ExRx.net'],
    // 이름: ko·en 은 출처 이름, 나머지는 🟦 번역.
    names: Exercise(
      '레그프레스 카프레이즈',
      'Leg Press Calf Raise',
      'レッグプレスカーフレイズ',
      '腿举机提踵',
      '腿推機提踵',
      'Elevación de Talones en Prensa',
      'Nhón Bắp Chân Máy Đạp Đùi',
      'เลกเพรสคาล์ฟเรส',
    ),
    cues: [
      // 🟩 exrx:Gastrocnemius/SL45CalfRaise "Position toes and balls of feet on foot platform with arches and heels extending off"
      (
        ko: '등을 패드에 대고 앞발만 발판에 올린다',
        en: 'Back on the pad; balls of the feet on the platform, heels off',
        basis: Basis.source,
      ),
      // 🟩 exrx:Gastrocnemius/SL45CalfRaise "Straighten knees"
      (ko: '무릎을 편다', en: 'Straighten your knees', basis: Basis.source),
      // 🟩 exrx:Gastrocnemius/SL45CalfRaise "Raise heels by extending ankles as high as possible"
      (
        ko: '뒤꿈치를 최대한 높이 들고, 종아리가 늘어날 때까지 내린다',
        en: 'Raise your heels as high as possible, then lower until your calves stretch',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Gastrocnemius/SL45CalfRaise "Quadriceps serve as synergist muscle if knees are bent slightly during stretch"
      (
        ko: '무릎을 굽혀 허벅지 힘을 보탠다',
        en: 'Bending the knees so the thighs help',
        basis: Basis.source,
      ),
      // 🟦
      (
        ko: '발이 발판에서 미끄러진다',
        en: 'Feet slipping on the platform',
        basis: Basis.none,
      ),
    ],
  ),
  // ── 헬스장 머신(2026-09-26 조사). 근육은 ExRx 등 원문(주석), 팁의 근거는 줄마다. ──
  // 아이소 래터럴 체스트 프레스 (Iso-Lateral Chest Press (plate-loaded, horizontal))
  // 근육 🟩 ← Target: Pectoralis Major, Sternal. Synergists: Pectoralis Major, Clavicular; Deltoid, Anterior; Triceps Brachii; Coracobrachialis. (Coracobrachialis has no enum id; Pectoralis Major Clavicular maps to chest = primary)
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/PectoralSternal/LVChestPressH
  '아이소 래터럴 체스트 프레스': Move(
    primary: [Muscle.chest],
    secondary: [
      Muscle.frontDelts,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on seat with chest approximately height of handles.
      (
        ko: '가슴이 손잡이 높이쯤 오도록 시트에 앉는다',
        en: 'Sit so your chest is about level with the handles',
        basis: Basis.source,
      ),
      // 🟩 Grasp handles with wide overhand grip; elbows out to sides just below shoulders.
      (
        ko: '넓은 오버핸드 그립, 팔꿈치는 어깨 바로 아래 옆으로',
        en: 'Wide overhand grip, elbows out to the sides just below the shoulders',
        basis: Basis.source,
      ),
      // 🟩 Press levers until arms are extended. Return weight until chest muscles are slightly stretched.
      (
        ko: '팔이 펴질 때까지 밀고, 가슴이 살짝 늘어날 때까지만 되돌린다',
        en: 'Press until arms extend; return until the chest is only slightly stretched',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will be compromised if grip is too wide.
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어듦',
        en: 'Gripping too wide, which cuts range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 인클라인 체스트 프레스 머신 (Incline Chest Press Machine)
  // 근육 🟦 ← Target: Pectoralis Major, Clavicular. Synergists: Pectoralis Major, Sternal; Deltoid, Anterior; Triceps Brachii. (Plate-loaded page LVInclineChestPressPL is not archived by the Wayback Machine; this is ExRx's Lever Incline Chest Press page, same movement on a lever machine)
  // 출처: https://web.archive.org/web/20251029151535/https://exrx.net/WeightExercises/PectoralClavicular/LVInclineChestPress
  '인클라인 체스트 프레스 머신': Move(
    primary: [Muscle.chest],
    secondary: [
      Muscle.frontDelts,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on seat with upper chest just above grips on lever.
      (
        ko: '윗가슴이 손잡이보다 살짝 위에 오도록 앉는다',
        en: 'Sit with your upper chest just above the grips',
        basis: Basis.source,
      ),
      // 🟩 Grasp handles with wide oblique overhand grip and position elbows out to sides.
      (
        ko: '넓은 오버핸드 그립, 팔꿈치는 옆으로',
        en: 'Wide overhand grip, elbows out to the sides',
        basis: Basis.source,
      ),
      // 🟩 Return weight until shoulders or chest feels slightly stretched.
      (
        ko: '어깨나 가슴이 살짝 늘어날 때까지만 되돌린다',
        en: 'Return only until the shoulders or chest feel slightly stretched',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will be compromised if grip is too wide
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어듦',
        en: 'Gripping too wide, which cuts range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 디클라인 체스트 프레스 머신 (Decline Chest Press Machine)
  // 근육 🟩 ← Target: Pectoralis Major, Sternal. Synergists: Pectoralis Major, Clavicular; Deltoid, Anterior; Triceps Brachii.
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/PectoralSternal/LVDeclineChestPressPL
  '디클라인 체스트 프레스 머신': Move(
    primary: [Muscle.chest],
    secondary: [
      Muscle.frontDelts,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on seat with lever grips lower chest height.
      (
        ko: '손잡이가 가슴 아래쪽 높이에 오도록 앉는다',
        en: 'Sit so the grips are at lower-chest height',
        basis: Basis.source,
      ),
      // 🟩 Grasp grips with wide overhand grip; elbows out to sides just below shoulders.
      (
        ko: '넓은 오버핸드 그립, 팔꿈치는 어깨 바로 아래 옆으로',
        en: 'Wide overhand grip, elbows out just below the shoulders',
        basis: Basis.source,
      ),
      // 🟩 Press lever until arms are extended. Return weight until chest muscles are slightly stretched.
      (
        ko: '팔이 펴질 때까지 밀고, 가슴이 살짝 늘어날 때까지만 되돌린다',
        en: 'Press to full extension; return until the chest is slightly stretched',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will be compromised if grip is too wide.
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어듦',
        en: 'Gripping too wide, which cuts range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 와이드 체스트 프레스 (Iso-Lateral Wide Chest Press)
  // 근육 🟦 ← No ExRx page found for Wide Chest; closest (Lever Chest Press, plate-loaded): Target: Pectoralis Major, Sternal. Synergists: Pectoralis Major, Clavicular; Deltoid, Anterior; Triceps Brachii; Coracobrachialis.
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/PectoralSternal/LVChestPressH
  '와이드 체스트 프레스': Move(
    primary: [Muscle.chest],
    secondary: [
      Muscle.frontDelts,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟦 Grasp handles with wide overhand grip; elbows out to sides just below shoulders.
      (
        ko: '팔꿈치는 어깨 바로 아래에서 옆으로 벌린다',
        en: 'Keep elbows out to the sides just below the shoulders',
        basis: Basis.adapted,
      ),
      // 🟦 Return weight until chest muscles are slightly stretched.
      (
        ko: '가슴이 살짝 늘어날 때까지만 되돌린다',
        en: 'Return only until the chest is slightly stretched',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟦 Range of motion will be compromised if grip is too wide.
      (
        ko: '그립을 과하게 넓혀 가동 범위가 줄어듦',
        en: 'Gripping excessively wide, which cuts range of motion',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 슈퍼 인클라인 프레스 (Iso-Lateral Super Incline Press)
  // 근육 🟦 ← Closest ExRx page (Lever Incline Chest Press on Military Press Machine): Target: Pectoralis Major, Clavicular. Synergists: Deltoid, Anterior; Triceps Brachii.
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/PectoralClavicular/LVInclineChestPressOnHammerMilitaryPress
  '슈퍼 인클라인 프레스': Move(
    primary: [Muscle.chest],
    secondary: [
      Muscle.frontDelts,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟦 Sit on seat with upper chest just above base of handles on lever.
      (
        ko: '윗가슴이 손잡이 밑동보다 살짝 위에 오도록 앉는다',
        en: 'Sit with your upper chest just above the base of the handles',
        basis: Basis.adapted,
      ),
      // 🟦 Lift levers into starting position with elbows slightly low.
      (
        ko: '시작할 때 팔꿈치를 살짝 낮게 두고 레버를 든다',
        en: 'Lift the levers into the start with elbows slightly low',
        basis: Basis.adapted,
      ),
      // 🟦 Return weight until chest muscles are slightly stretched with elbows positioned out to sides.
      (
        ko: '팔꿈치를 옆으로 두고 가슴이 살짝 늘어날 때까지만 내린다',
        en: 'Lower with elbows out until the chest is slightly stretched',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟦 lower levers only as far back to allow slight stretch to be felt in chest or shoulders.
      (
        ko: '가슴이나 어깨가 살짝 늘어나는 지점보다 더 깊이 내림',
        en: 'Lowering past a slight stretch in the chest or shoulders',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 스미스머신 벤치프레스 (Smith Machine Bench Press)
  // 근육 🟩 ← Target: Pectoralis Major, Sternal. Synergists: Pectoralis Major, Clavicular; Deltoid, Anterior; Triceps Brachii.
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/PectoralSternal/SMBenchPress
  '스미스머신 벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [
      Muscle.frontDelts,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Lie supine on bench with chest under bar.
      (
        ko: '가슴이 바 아래에 오도록 벤치에 눕는다',
        en: 'Lie on the bench with your chest under the bar',
        basis: Basis.source,
      ),
      // 🟩 Disengage bar by rotating bar back.
      (
        ko: '바를 뒤로 돌려 걸쇠를 푼다',
        en: 'Unhook the bar by rotating it back',
        basis: Basis.source,
      ),
      // 🟩 Lower weight to chest. Press bar until arms are extended.
      (
        ko: '가슴까지 내리고 팔이 펴질 때까지 민다',
        en: 'Lower to the chest, then press until arms are extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will be compromised if grip is too wide.
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어듦',
        en: 'Gripping too wide, which cuts range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 스미스머신 인클라인 벤치프레스 (Smith Machine Incline Bench Press)
  // 근육 🟩 ← Target: Pectoralis Major, Clavicular. Synergists: Pectoralis Major, Sternal; Deltoid, Anterior; Triceps Brachii; Coracobrachialis.
  // 출처: https://web.archive.org/web/2024/https://exrx.net/WeightExercises/PectoralClavicular/SMInclineBenchPress
  '스미스머신 인클라인 벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [
      Muscle.frontDelts,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Lie supine on incline bench with upper chest under bar.
      (
        ko: '윗가슴이 바 아래에 오도록 인클라인 벤치에 눕는다',
        en: 'Lie on the incline bench with your upper chest under the bar',
        basis: Basis.source,
      ),
      // 🟩 Disengage bar by rotating bar back.
      (
        ko: '바를 뒤로 돌려 걸쇠를 푼다',
        en: 'Unhook the bar by rotating it back',
        basis: Basis.source,
      ),
      // 🟩 Lower weight to upper chest. Press bar until arms are extended.
      (
        ko: '윗가슴까지 내리고 팔이 펴질 때까지 민다',
        en: 'Lower to the upper chest, then press until arms are extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will be compromised if grip is too wide.
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어듦',
        en: 'Gripping too wide, which cuts range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 시티드 딥스 머신 (Seated Dip Machine)
  // 근육 🟩 ← Target: Triceps Brachii. Synergists: Deltoid, Anterior; Pectoralis Major, Sternal; Pectoralis Major, Clavicular; Pectoralis Minor; Rhomboids; Levator Scapulae; Latissimus Dorsi. (Pectoralis Minor has no enum id)
  // 출처: https://web.archive.org/web/2024/https://exrx.net/WeightExercises/Triceps/LVTriDip
  '시티드 딥스 머신': Move(
    primary: [Muscle.tricepsLong, Muscle.tricepsLateral, Muscle.tricepsMedial],
    secondary: [Muscle.frontDelts, Muscle.chest, Muscle.upperBack, Muscle.lats],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 If possible, place handles in narrow position. Sit on seat with back against pad.
      (
        ko: '가능하면 손잡이를 좁은 위치로 두고 등을 패드에 붙여 앉는다',
        en: 'Set handles narrow if possible; sit with your back against the pad',
        basis: Basis.source,
      ),
      // 🟩 Push levers down by straightening arms downward.
      (
        ko: '팔꿈치를 뒤로 향하게 하고 팔을 아래로 펴며 민다',
        en: 'Elbows pointing back, push the levers down by straightening your arms',
        basis: Basis.source,
      ),
      // 🟩 Allow lever bar to raise with elbows pointing back until shoulders are slightly stretched.
      (
        ko: '어깨가 살짝 늘어날 때까지만 올라오게 둔다',
        en: 'Let the lever rise only until the shoulders are slightly stretched',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 Allow lever bar to raise with elbows pointing back until shoulders are slightly stretched.
      (
        ko: '어깨가 과하게 늘어날 만큼 깊이 올라오게 둠',
        en: 'Letting the lever rise past a slight shoulder stretch',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 어시스트 딥스 (Assisted Dip (machine))
  // 근육 🟩 ← Target: Triceps Brachii. Synergists: Deltoid, Anterior; Pectoralis Major, Sternal; Pectoralis Major, Clavicular; Pectoralis Minor; Rhomboids; Levator Scapulae; Latissimus Dorsi; Coracobrachialis. (Pectoralis Minor, Coracobrachialis have no enum id)
  // 출처: https://web.archive.org/web/2024/https://exrx.net/WeightExercises/Triceps/ASTriDip
  '어시스트 딥스': Move(
    primary: [Muscle.tricepsLong, Muscle.tricepsLateral, Muscle.tricepsMedial],
    secondary: [Muscle.frontDelts, Muscle.chest, Muscle.upperBack, Muscle.lats],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Mount shoulder width dip bar, arms straight with shoulders above hands.
      (
        ko: '팔을 펴고 어깨가 손 위에 오게 바에 올라선다',
        en: 'Mount the bars with arms straight and shoulders above hands',
        basis: Basis.source,
      ),
      // 🟩 Step down onto assistance lever. Keep hips and knees straight.
      (
        ko: '보조 레버에 올라서고 엉덩이와 무릎은 곧게 편다',
        en: 'Step onto the assist lever; keep hips and knees straight',
        basis: Basis.source,
      ),
      // 🟩 Lower body until slight stretch is felt in shoulders. Push body up until arms are straight.
      (
        ko: '어깨가 살짝 늘어날 때까지 내려갔다가 팔이 펴질 때까지 민다',
        en: 'Lower until a slight shoulder stretch, then push up until arms are straight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 Lower body until slight stretch is felt in shoulders.
      (
        ko: '어깨가 살짝 늘어나는 지점보다 더 깊이 내려감',
        en: 'Dropping deeper than a slight shoulder stretch',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 어시스트 풀업 (Assisted Pull-up (machine))
  // 근육 🟩 ← Target: Latissimus Dorsi. Synergists: Brachialis; Brachioradialis; Biceps Brachii; Teres Major; Deltoid, Posterior; Infraspinatus; Teres Minor; Rhomboids; Levator Scapulae; Trapezius, Lower; Trapezius, Middle; Pectoralis Minor. (Pectoralis Minor has no enum id)
  // 출처: https://web.archive.org/web/2021/https://exrx.net/WeightExercises/LatissimusDorsi/AsPullupKneeling
  '어시스트 풀업': Move(
    primary: [Muscle.lats],
    secondary: [
      Muscle.biceps,
      Muscle.forearms,
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.upperBack,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Step up and grasp bar with wide overhand grip. Kneel on padded platform and lower body down with arm extended.
      (
        ko: '넓은 오버핸드 그립으로 바를 잡고 패드에 무릎을 꿇는다',
        en: 'Grip the bar wide overhand and kneel on the pad',
        basis: Basis.source,
      ),
      // 🟩 Pull body up until neck reaches height of hands.
      (
        ko: '목이 손 높이에 올 때까지 당긴다',
        en: 'Pull up until your neck reaches hand height',
        basis: Basis.source,
      ),
      // 🟩 Lower body until arms and shoulders are fully extended.
      (
        ko: '팔과 어깨가 완전히 펴질 때까지 내려온다',
        en: 'Lower until arms and shoulders are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will decrease if grip is too wide
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어듦',
        en: 'Gripping too wide, which cuts range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 하이 로우 (High Row Machine)
  // 근육 🟦 ← Target: Back, General. Synergists: Trapezius, Middle; Trapezius, Lower; Rhomboids; Latissimus Dorsi; Teres Major; Deltoid, Posterior; Infraspinatus; Teres Minor; Brachialis; Brachioradialis; Pectoralis Major, Sternal. Dynamic Stabilizers: Biceps Brachii; Triceps, Long Head (LVSeatedHighRowPL has no
  // 출처: https://web.archive.org/web/20230531190822/https://exrx.net/WeightExercises/BackGeneral/LVSeatedHighRow
  '하이 로우': Move(
    primary: [Muscle.upperBack, Muscle.lats],
    secondary: [
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Pull lever back until elbows are behind back and shoulders are pulled back.
      (
        ko: '팔꿈치가 등 뒤로 갈 때까지 당기고 어깨를 뒤로 모은다',
        en: 'Pull until elbows are behind the back and shoulders are pulled back',
        basis: Basis.source,
      ),
      // 🟩 Return until arms are extended and shoulders are stretched forward.
      (
        ko: '돌아갈 때는 팔을 펴고 어깨가 앞으로 늘어나게 둔다',
        en: 'Return until arms are extended and shoulders stretch forward',
        basis: Basis.source,
      ),
      // 🟩 The seat or grip should be adjusted to allow wrists to follow elbows.
      (
        ko: '손목이 팔꿈치를 따라가도록 시트·손잡이 높이를 맞춘다',
        en: 'Set seat or grip so wrists follow the elbows',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Chest pad should be adjusted to allow shoulders to stretch forward.
      (
        ko: '가슴 패드를 너무 뒤로 두어 어깨가 앞으로 늘어나지 못하게 하는 것',
        en: 'Setting the chest pad so the shoulders cannot stretch forward',
        basis: Basis.source,
      ),
    ],
  ),
  // 머신 로우로우 (Low Row Machine)
  // 근육 🟦 ← Target: Back, General. Synergists: Trapezius, Middle; Trapezius, Lower; Rhomboids; Latissimus Dorsi; Teres Major; Deltoid, Posterior; Infraspinatus; Teres Minor; Brachialis; Brachioradialis; Pectoralis Major, Sternal. Dynamic Stabilizers: Biceps Brachii; Triceps, Long Head
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/BackGeneral/LVSeatedLowRow
  '머신 로우로우': Move(
    primary: [Muscle.upperBack, Muscle.lats],
    secondary: [
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on seat and position chest against pad. Grasp lever handles with overhand/neutral grip.
      (
        ko: '가슴을 패드에 대고 오버핸드/뉴트럴 그립으로 잡는다',
        en: 'Chest on the pad, overhand or neutral grip',
        basis: Basis.source,
      ),
      // 🟩 When completing pull, lift chest slightly and pull shoulder blades together while keeping lower chest on pad.
      (
        ko: '마지막에 가슴을 살짝 들고 견갑을 모으되 아랫가슴은 패드에 붙인다',
        en: 'At the finish, lift the chest slightly and squeeze the shoulder blades, lower chest stays on the pad',
        basis: Basis.source,
      ),
      // 🟩 Let shoulders roll forward when arms extend.
      (
        ko: '팔을 펼 때 어깨가 앞으로 말리게 둔다',
        en: 'Let the shoulders roll forward as the arms extend',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Seat or grip should be adjusted to allow wrists to follow elbows.
      (
        ko: '손목이 팔꿈치를 따라가지 않게 시트·그립을 맞추지 않는 것',
        en: 'Not adjusting seat or grip so the wrists follow the elbows',
        basis: Basis.source,
      ),
    ],
  ),
  // 아이소 래터럴 로우 (Iso-Lateral Row (chest-supported plate-loaded row))
  // 근육 🟦 ← Target: Back, General. Synergists: Trapezius, Middle; Trapezius, Lower; Rhomboids; Latissimus Dorsi; Teres Major; Deltoid, Posterior; Infraspinatus; Teres Minor; Brachialis; Brachioradialis; Pectoralis Major, Sternal. Dynamic Stabilizers: Biceps Brachii; Triceps, Long Head
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/BackGeneral/LVNarrowGripSeatedRowH
  '아이소 래터럴 로우': Move(
    primary: [Muscle.upperBack, Muscle.lats],
    secondary: [
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on seat and position chest against pad.
      (
        ko: '가슴을 패드에 대고 앉는다',
        en: 'Sit with the chest against the pad',
        basis: Basis.source,
      ),
      // 🟩 Pull levers back until elbows are behind back and shoulders are pulled back.
      (
        ko: '팔꿈치가 등 뒤로 갈 때까지 당기고 어깨를 뒤로 모은다',
        en: 'Pull until elbows are behind the back and shoulders are pulled back',
        basis: Basis.source,
      ),
      // 🟩 Return until arms are extended and shoulders are stretched forward.
      (
        ko: '팔을 다 펴고 어깨가 앞으로 늘어나게 돌아간다',
        en: 'Return until arms are extended and shoulders stretch forward',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 pull shoulder blades together while keeping lower chest on pad.
      (
        ko: '당길 때 아랫가슴이 패드에서 떨어지는 것',
        en: 'Lifting the lower chest off the pad during the pull',
        basis: Basis.source,
      ),
    ],
  ),
  // DY 로우 (Iso-Lateral D.Y. Row)
  // 근육 🟦 ← Target: Back, General. Synergists: Trapezius, Middle; Trapezius, Lower; Rhomboids; Latissimus Dorsi; Teres Major; Deltoid, Posterior; Infraspinatus; Teres Minor; Brachialis; Brachioradialis; Pectoralis Major, Sternal. Dynamic Stabilizers: Biceps Brachii; Triceps, Long Head (no ExRx page for D.Y. Row
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/BackGeneral/LVSeatedUnderhandRow
  'DY 로우': Move(
    primary: [Muscle.upperBack, Muscle.lats],
    secondary: [
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟦 Grasp lever handles with underhand grip.
      (
        ko: '언더핸드 그립으로 손잡이를 잡는다',
        en: 'Grasp the handles with an underhand grip',
        basis: Basis.adapted,
      ),
      // 🟦 Pull levers back until elbows are behind back and shoulders are pulled back.
      (
        ko: '팔꿈치가 등 뒤로 갈 때까지 당기고 어깨를 뒤로 모은다',
        en: 'Pull until elbows are behind the back and shoulders are pulled back',
        basis: Basis.adapted,
      ),
      // 🟦 When completing pull, lift chest slightly and pull shoulder blades together while keeping lower chest on pad.
      (
        ko: '마지막에 가슴을 살짝 들고 견갑을 모은다',
        en: 'At the finish, lift the chest slightly and squeeze the shoulder blades',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟦 Seat or grip should be adjusted to allow wrists to follow elbows.
      (
        ko: '손목이 팔꿈치를 따라가지 않게 시트·그립을 두는 것',
        en: 'Seat or grip set so the wrists do not follow the elbows',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 머신 랫풀다운 (Machine Lat Pulldown (front / iso-lateral))
  // 근육 🟩 ← Target: Latissimus Dorsi. Synergists: Brachialis; Brachioradialis; Biceps Brachii; Teres Major; Deltoid, Posterior; Infraspinatus; Teres Minor; Rhomboids; Levator Scapulae; Trapezius, Lower; Trapezius, Middle; Pectoralis Minor. Dynamic Stabilizers: Triceps, Long Head
  // 출처: https://web.archive.org/web/20230605085034/https://exrx.net/WeightExercises/LatissimusDorsi/LVFrontPulldown
  '머신 랫풀다운': Move(
    primary: [Muscle.lats],
    secondary: [
      Muscle.biceps,
      Muscle.forearms,
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.infraspinatus,
      Muscle.teresMinor,
      Muscle.upperBack,
      Muscle.chest,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit with thighs under supports.
      (
        ko: '허벅지를 지지대 아래에 고정하고 앉는다',
        en: 'Sit with thighs locked under the supports',
        basis: Basis.source,
      ),
      // 🟩 Pull down lever to upper chest.
      (
        ko: '손잡이를 윗가슴까지 당긴다',
        en: 'Pull the lever down to the upper chest',
        basis: Basis.source,
      ),
      // 🟩 Return until arms and shoulders are fully extended.
      (
        ko: '팔과 어깨가 완전히 펴질 때까지 올려 보낸다',
        en: 'Return until arms and shoulders are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 Return until arms and shoulders are fully extended.
      (
        ko: '반동으로 끝까지 올리지 않고 짧게 반복하는 것',
        en: 'Cutting the top short instead of fully extending arms and shoulders',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 와이드 풀다운 (Iso-Lateral Wide Pulldown)
  // 근육 🟦 ← Target: Latissimus Dorsi. Synergists: Brachialis; Brachioradialis; Biceps Brachii; Teres Major; Rhomboids; Levator Scapulae; Pectoralis Minor; Trapezius, Lower; Pectoralis Major, Sternal; Coracobrachialis. Dynamic Stabilizers: Triceps, Long Head (LVPulldownH not retrievable; this is Lever Pulldown [
  // 출처: https://web.archive.org/web/20250826162959/https://exrx.net/WeightExercises/LatissimusDorsi/LVPulldown
  '와이드 풀다운': Move(
    primary: [Muscle.lats],
    secondary: [
      Muscle.biceps,
      Muscle.forearms,
      Muscle.teresMajor,
      Muscle.upperBack,
      Muscle.chest,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Reach up and grasp handles with wide overhand grip.
      (
        ko: '넓은 오버핸드 그립으로 손잡이를 잡는다',
        en: 'Grasp the handles with a wide overhand grip',
        basis: Basis.source,
      ),
      // 🟩 Pull levers down to sides of shoulders.
      (
        ko: '손잡이를 어깨 옆까지 끌어내린다',
        en: 'Pull the levers down to the sides of the shoulders',
        basis: Basis.source,
      ),
      // 🟩 Return until arms and shoulders are fully extended.
      (
        ko: '팔과 어깨가 완전히 펴질 때까지 돌아간다',
        en: 'Return until arms and shoulders are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will be compromised if grip is too wide.
      (
        ko: '그립을 지나치게 넓게 잡아 가동범위를 잃는 것',
        en: 'Gripping too wide and losing range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 풀오버 머신 (Pullover Machine)
  // 근육 🟩 ← Target: Latissimus Dorsi. Synergists: Pectoralis Major, Sternal; Pectoralis Minor; Triceps, Long Head; Teres Major; Deltoid, Posterior; Rhomboids; Levator Scapulae. Stabilizers: Trapezius, Lower
  // 출처: https://web.archive.org/web/20240105211036/https://exrx.net/WeightExercises/LatissimusDorsi/LVPullover
  '풀오버 머신': Move(
    primary: [Muscle.lats],
    secondary: [
      Muscle.chest,
      Muscle.tricepsLong,
      Muscle.teresMajor,
      Muscle.rearDelts,
      Muscle.upperBack,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Adjust seat height so lever is near shoulder axis.
      (
        ko: '레버 축이 어깨 축 근처에 오도록 시트 높이를 맞춘다',
        en: 'Set seat height so the lever is near the shoulder axis',
        basis: Basis.source,
      ),
      // 🟩 Pull lever forward and down until elbows are to sides.
      (
        ko: '팔꿈치를 패드에 대고 앞·아래로 당겨 팔꿈치가 옆구리에 오게 한다',
        en: 'Elbows on pads; pull forward and down until elbows reach your sides',
        basis: Basis.source,
      ),
      // 🟩 When finished, push foot lever before releasing arm from lever.
      (
        ko: '끝나면 팔을 빼기 전에 발 레버를 먼저 민다',
        en: 'When finished, push the foot lever before releasing your arms',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Actual range of motion is dependent upon individual shoulder flexibility.
      (
        ko: '어깨 유연성을 넘어서 억지로 가동범위를 늘리는 것',
        en: 'Forcing range beyond your shoulder flexibility',
        basis: Basis.source,
      ),
    ],
  ),
  // 백 익스텐션 머신 (Back Extension Machine)
  // 근육 🟩 ← Target: Erector Spinae. Synergists (see comments): Gluteus Maximus; Adductor Magnus; Hamstrings. Stabilizers: Quadriceps
  // 출처: https://web.archive.org/web/20231213140134/https://exrx.net/WeightExercises/ErectorSpinae/LVBackExtension
  '백 익스텐션 머신': Move(
    primary: [Muscle.lowerBack],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.hamstrings],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit in machine with feet on platform, back under padded lever, and hips against back of seat.
      (
        ko: '발은 발판에, 등은 패드 아래, 엉덩이는 시트 뒤에 붙인다',
        en: 'Feet on platform, back under the pad, hips against the back of the seat',
        basis: Basis.source,
      ),
      // 🟩 Extend lower hips and low back until extended.
      (
        ko: '엉덩이와 허리를 펴서 끝까지 신전한다',
        en: 'Extend hips and low back until fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Those with limited hip flexor flexibility may need to stop before full extension on this particular type of apparatus (fulcrum near hip).
      (
        ko: '고관절 굴곡근 유연성이 부족한데 끝까지 억지로 펴는 것',
        en: 'Forcing full extension with limited hip flexor flexibility',
        basis: Basis.source,
      ),
    ],
  ),
  // 리버스 하이퍼 (Reverse Hyperextension)
  // 근육 🟩 ← Target: Gluteus Maximus. Synergists: Hamstrings. Stabilizers: Erector Spinae. Antagonist Stabilizers: Rectus Abdominis; Obliques
  // 출처: https://web.archive.org/web/20251025035459/https://exrx.net/WeightExercises/GluteusMaximus/LVReverseHyperextension
  '리버스 하이퍼': Move(
    primary: [Muscle.glutes],
    secondary: [Muscle.hamstrings],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Lay torso and waist on bench and grasp handles.
      (
        ko: '상체를 벤치에 엎드리고 손잡이를 잡아 다리를 곧게 늘어뜨린다',
        en: 'Lie torso on the bench, grip the handles, legs hanging straight down',
        basis: Basis.source,
      ),
      // 🟩 Raise lever by extending hips as high as possible with legs nearly straight.
      (
        ko: '다리를 거의 편 채 엉덩이를 펴서 최대한 높이 올린다',
        en: 'Raise the legs by extending the hips as high as possible, legs nearly straight',
        basis: Basis.source,
      ),
      // 🟩 Lower legs to original position.
      (
        ko: '처음 위치로 내린다',
        en: 'Lower the legs to the starting position',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 백 익스텐션(exrx:ErectorSpinae/BW45HyperextensionHips "Do not lower weight beyond mild stretch throughout hamstrings and low back")에서 옮김
      (
        ko: '가볍게 늘어나는 느낌을 넘어 깊이 내려간다',
        en: 'Lowering past a mild stretch',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 글루트 햄 레이즈 (Glute Ham Raise)
  // 근육 🟦 ← Target: Hamstrings. Synergists: Gluteus Maximus; Adductor Magnus; Gastrocnemius; Sartorius; Gracilis; Popliteus. Stabilizers: Erector Spinae. Antagonist Stabilizers: Rectus Abdominis; Obliques; Tibialis Anterior (BWGluteHamRaiseHips not archived; this is the barbell Glute-Ham Raise page; Sartorius/P
  // 출처: https://web.archive.org/web/20260313082021/https://exrx.net/WeightExercises/Hamstrings/BBGluteHamRaise
  '글루트 햄 레이즈': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Place ankles between ankle roller pads with feet on vertical platform and position knees on pad with lower thighs against large padded hump.
      (
        ko: '발목을 롤러 사이에 끼우고 무릎은 패드에, 허벅지 아래쪽은 둥근 패드에 댄다',
        en: 'Ankles between the rollers, knees on the pad, lower thighs against the hump',
        basis: Basis.source,
      ),
      // 🟩 From lower position, raise torso by extending hips until fully extended. Continue to raise body by flexing knees until body is upright.
      (
        ko: '엉덩이를 먼저 펴고, 이어서 무릎을 굽혀 몸을 세운다',
        en: 'Extend the hips first, then flex the knees to bring the body upright',
        basis: Basis.source,
      ),
      // 🟩 Exercise can be performed without added weight until more resistance is needed.
      (
        ko: '힘이 붙기 전에는 무게 없이 한다',
        en: 'Do it without added weight until you need more resistance',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 백 익스텐션(exrx:ErectorSpinae/BW45HyperextensionHips "Do not lower weight beyond mild stretch throughout hamstrings and low back")에서 옮김
      (
        ko: '가볍게 늘어나는 느낌을 넘어 깊이 내려간다',
        en: 'Lowering past a mild stretch',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 노르딕 햄 컬 (Assisted Nordic Hamstring Curl (machine))
  // 근육 🟦 ← Target: Hamstrings. Synergists: Gastrocnemius Gracilis Sartorius Popliteus Pectoralis Major, Sternal Pectoralis Major, Clavicular Deltoid, Anterior Triceps Brachii Wrist Flexors (closest page: self-assisted hamstring raise; arm push-off synergists omitted because the machine supplies the assist)
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Hamstrings/ASHamstringRaiseSelf
  '노르딕 햄 컬': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.calves],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟦 Lower body with hips straight by slowly straightening knees.
      (
        ko: '엉덩이를 편 채로 무릎만 천천히 펴며 내려간다',
        en: 'Lower your body with hips straight by slowly straightening the knees',
        basis: Basis.adapted,
      ),
      // 🟦 Control descent only with hamstrings as low as possible
      (
        ko: '햄스트링만으로 최대한 낮게까지 버티며 내려간다',
        en: 'Control the descent with the hamstrings as low as you can',
        basis: Basis.adapted,
      ),
      // 🟦 push off only hard enough to minimally assist raising of body with hamstrings only.
      (
        ko: '도움은 올라올 만큼만 최소로',
        en: 'Use only as much assist as you need to rise',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟦 Lower body with hips straight by slowly straightening knees.
      (
        ko: '엉덩이를 접어 허리로 버티기',
        en: 'Bending at the hips instead of keeping them straight',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 머신 레터럴 레이즈 (Lateral Raise Machine)
  // 근육 🟩 ← Target: Deltoid, Lateral. Synergists: Deltoid, Anterior Supraspinatus Trapezius, Middle Trapezius, Lower Serratus Anterior, Inferior Digitations
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/DeltoidLateral/LVLateralRaise
  '머신 레터럴 레이즈': Move(
    primary: [Muscle.sideDelts],
    secondary: [Muscle.frontDelts, Muscle.upperBack],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Situate bent arms between padded lever and sides of body.
      (
        ko: '팔을 굽혀 패드와 몸통 사이에 둔다',
        en: 'Place bent arms between the pads and your sides',
        basis: Basis.source,
      ),
      // 🟩 Raise arms to sides until upper arms are horizontal.
      (
        ko: '위팔이 수평이 될 때까지 옆으로 든다',
        en: 'Raise arms to the sides until upper arms are horizontal',
        basis: Basis.source,
      ),
      // 🟩 If necessary, lean forward slightly to keep elbows directly lateral to body.
      (
        ko: '필요하면 살짝 앞으로 기울여 팔꿈치를 몸 옆에 둔다',
        en: 'Lean forward slightly if needed to keep elbows directly to the side',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 Raise arms to sides until upper arms are horizontal.
      (
        ko: '위팔을 수평보다 높이 들어 올리기',
        en: 'Raising the upper arms above horizontal',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 바이킹 프레스 (Viking Press)
  // 근육 🟦 ← Target: Deltoid, Anterior. Synergists: Pectoralis Major, Clavicular Triceps Brachii Deltoid, Lateral Trapezius, Middle Trapezius, Lower Serratus Anterior, Inferior Digitations (closest page: Lever Shoulder Press, parallel grip; no ExRx Viking Press page found)
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/DeltoidAnterior/LVShoulderPressParGrip
  '바이킹 프레스': Move(
    primary: [Muscle.frontDelts],
    secondary: [
      Muscle.chest,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
      Muscle.sideDelts,
      Muscle.upperBack,
    ],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟦 Sit on seat and grasp parallel bar grips in front of shoulders on each side.
      (
        ko: '어깨 앞에서 평행 손잡이를 잡는다',
        en: 'Grip the parallel handles in front of the shoulders',
        basis: Basis.adapted,
      ),
      // 🟦 Press lever upward until arms are extended overhead. Lower and repeat.
      (
        ko: '팔이 머리 위로 펴질 때까지 민다',
        en: 'Press until arms are extended overhead',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      (
        ko: '허리를 과하게 젖혀 밀기',
        en: 'Over-arching the lower back to press',
        basis: Basis.none,
      ),
    ],
  ),
  // 스미스머신 숄더프레스 (Smith Machine Shoulder Press)
  // 근육 🟩 ← Target: Deltoid, Anterior. Synergists: Pectoralis Major, Clavicular Triceps Brachii Deltoid, Lateral Trapezius, Middle Trapezius, Lower Serratus Anterior, Inferior Digitations
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/DeltoidAnterior/SMShoulderPress
  '스미스머신 숄더프레스': Move(
    primary: [Muscle.frontDelts],
    secondary: [
      Muscle.chest,
      Muscle.tricepsLong,
      Muscle.tricepsLateral,
      Muscle.tricepsMedial,
      Muscle.sideDelts,
      Muscle.upperBack,
    ],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on bench with bar positioned in front of shoulders. Grasp bar with wide overhand grip.
      (
        ko: '바를 어깨 앞에 두고 넓게 오버그립으로 잡는다',
        en: 'Bar in front of shoulders, wide overhand grip',
        basis: Basis.source,
      ),
      // 🟩 Press bar upward until arms are extended overhead. Lower bar to front of shoulders and repeat.
      (
        ko: '팔이 머리 위로 펴질 때까지 밀고 어깨 앞까지 내린다',
        en: 'Press until arms extend overhead, lower to front of shoulders',
        basis: Basis.source,
      ),
      // 🟩 Pull head back slightly so bar does not make contact with head.
      (
        ko: '머리를 살짝 뒤로 빼 바가 닿지 않게',
        en: 'Pull head back slightly so the bar clears it',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Range of motion will be compromised if grip is too wide .
      (
        ko: '그립을 너무 넓게 잡아 가동범위 줄이기',
        en: 'Gripping too wide, which cuts range of motion',
        basis: Basis.source,
      ),
    ],
  ),
  // 머신 바이셉스 컬 (Biceps Curl Machine)
  // 근육 🟩 ← Target: Brachialis. Synergists: Biceps Brachii Brachioradialis
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Brachialis/LVPreacherCurl
  '머신 바이셉스 컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Align elbows at same pivot point as fulcrum of lever.
      (
        ko: '팔꿈치를 기계 회전축에 맞춘다',
        en: 'Align elbows with the machine\'s pivot point',
        basis: Basis.source,
      ),
      // 🟩 Seat should be adjusted to allow armpit to rest near top of pad.
      (
        ko: '겨드랑이가 패드 위쪽에 닿게 의자 높이를 맞춘다',
        en: 'Set the seat so the armpit rests near the top of the pad',
        basis: Basis.source,
      ),
      // 🟩 Lower handles until arms are fully extended.
      (
        ko: '팔을 끝까지 펴서 내린다',
        en: 'Lower until arms are fully extended',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Back of upper arm should remain on pad throughout movement.
      (
        ko: '위팔 뒤쪽이 패드에서 떨어지기',
        en: 'Letting the back of the upper arm lift off the pad',
        basis: Basis.source,
      ),
    ],
  ),
  // 머신 트라이셉스 익스텐션 (Triceps Extension Machine)
  // 근육 🟩 ← Target: Triceps Brachii. Synergists: None
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Triceps/LVTriExt
  '머신 트라이셉스 익스텐션': Move(
    primary: [Muscle.tricepsLong, Muscle.tricepsLateral, Muscle.tricepsMedial],
    secondary: [],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Grasp handles and place back of upper arms parallel on padding with elbows approximately in line with lever's fulcrum.
      (
        ko: '위팔 뒤쪽을 패드에 대고 팔꿈치를 회전축에 맞춘다',
        en: 'Upper arms on the pad, elbows in line with the pivot',
        basis: Basis.source,
      ),
      // 🟩 Push lever down until arms are fully extended.
      (
        ko: '팔이 완전히 펴질 때까지 민다',
        en: 'Push until arms are fully extended',
        basis: Basis.source,
      ),
      // 🟩 Adjust seat height, so back of upper arms rest on padding.
      (
        ko: '위팔이 패드에 닿도록 의자 높이를 맞춘다',
        en: 'Adjust seat height so upper arms rest on the pad',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 If seat is too high, shoulder will need to rise near end of extension to complete final range of motion
      (
        ko: '의자가 너무 높아 끝에서 어깨가 들림',
        en: 'Seat too high, so the shoulder rises at lockout',
        basis: Basis.source,
      ),
    ],
  ),
  // V 스쿼트 (V-Squat Machine)
  // 근육 🟩 ← Target: Quadriceps. Synergists: Gluteus Maximus Adductor Magnus Soleus
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Quadriceps/LVVSquat
  'V 스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Position shoulders under shoulder pads with back against back pad.
      (
        ko: '어깨를 패드 아래, 등을 등받이에 붙인다',
        en: 'Shoulders under the pads, back against the back pad',
        basis: Basis.source,
      ),
      // 🟩 Place feet on platform, shoulder or hip width apart.
      (
        ko: '발은 어깨나 골반 너비로',
        en: 'Feet shoulder or hip width apart',
        basis: Basis.source,
      ),
      // 🟩 Squat down with knees pointed same direction as feet.
      (
        ko: '무릎은 발끝과 같은 방향으로 앉는다',
        en: 'Squat with knees pointed the same way as the feet',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 If insufficient, hip flexibility forces pelvis to pull away from back pad at lower portions of movement, only lower sled just short of spinal articulation.
      (
        ko: '깊이 내려가며 골반이 등받이에서 떨어지기',
        en: 'Pelvis pulling away from the back pad at the bottom',
        basis: Basis.source,
      ),
    ],
  ),
  // 스쿼트 머신 (Squat Press Machine (lever squat))
  // 근육 🟩 ← Target: Quadriceps. Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Quadriceps/LVSquatPL
  '스쿼트 머신': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Lower lever by bending hips back while allowing knees to bend forward, keeping back straight and knees pointed same direction as feet.
      (
        ko: '엉덩이를 뒤로 빼며 무릎을 굽혀 내려가기',
        en: 'Lower by bending hips back while knees bend forward',
        basis: Basis.source,
      ),
      // 🟩 Descend until thighs are just past parallel to floor.
      (
        ko: '허벅지가 평행을 살짝 지날 때까지',
        en: 'Descend until thighs are just past parallel',
        basis: Basis.source,
      ),
      // 🟩 Keep head facing forward, back straight and feet flat on floor with equal distribution of weight through forefoot and heel.
      (
        ko: '발바닥 전체로 고르게 밀기',
        en: 'Keep feet flat, weight through forefoot and heel',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Knees should point same direction as feet throughout movement.
      (
        ko: '무릎이 안쪽으로 모이기',
        en: 'Knees caving away from toe direction',
        basis: Basis.source,
      ),
    ],
  ),
  // 스미스머신 스쿼트 (Smith Machine Squat)
  // 근육 🟩 ← Target: Quadriceps. Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Quadriceps/SMSquat
  '스미스머신 스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 With bar upper chest height, position bar on back of shoulders and grasp bar to sides. Place feet under bar.
      (
        ko: '바를 어깨 뒤에 얹고 발은 바 아래에',
        en: 'Bar on back of shoulders, feet under the bar',
        basis: Basis.source,
      ),
      // 🟩 Descend until thighs are just past parallel to floor.
      (
        ko: '허벅지가 평행을 살짝 지날 때까지 앉기',
        en: 'Squat until thighs are just past parallel',
        basis: Basis.source,
      ),
      // 🟩 Keep head facing forward, back straight and feet flat on floor with equal distribution of weight through forefoot and heel.
      (
        ko: '등은 곧게, 발바닥 전체로 체중 분산',
        en: 'Back straight, weight spread over forefoot and heel',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Knees should point same direction as feet throughout movement.
      (
        ko: '무릎과 발끝 방향이 어긋나기',
        en: 'Knees not tracking the toes',
        basis: Basis.source,
      ),
    ],
  ),
  // 45도 레그프레스 (45° Leg Press (sled))
  // 근육 🟩 ← Target: Quadriceps. Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Quadriceps/SL45LegPress
  '45도 레그프레스': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Keep knees pointed same directions as feet.
      (
        ko: '무릎은 발끝과 같은 방향',
        en: 'Keep knees pointed same direction as feet',
        basis: Basis.source,
      ),
      // 🟩 Do not allow heels to raise off of platform, pushing with both heel and forefoot.
      (
        ko: '뒤꿈치와 앞꿈치로 함께 밀기',
        en: 'Push with both heel and forefoot',
        basis: Basis.source,
      ),
      // 🟩 Placing feet slightly high on platform emphasizes Gluteus Maximus. Placing feet slightly lower on platform emphasizes Quadriceps.
      (
        ko: '발을 높게 두면 둔근, 낮게 두면 대퇴사두 강조',
        en: 'Feet high emphasizes glutes, low emphasizes quads',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Adjust safety brace and back support to accommodate near full range of motion without forcing hips to bend at waist.
      (
        ko: '너무 깊게 내려 허리가 말리기',
        en: 'Going so deep the hips/lower back round',
        basis: Basis.source,
      ),
      // 🟩 Do not allow heels to raise off of platform
      (
        ko: '뒤꿈치가 발판에서 뜨기',
        en: 'Heels lifting off the platform',
        basis: Basis.source,
      ),
    ],
  ),
  // 시티드 레그프레스 (Seated (Horizontal) Leg Press)
  // 근육 🟩 ← Target: Quadriceps. Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Quadriceps/LVSeatedLegPress
  '시티드 레그프레스': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Keep knees pointed same directions as feet.
      (
        ko: '무릎은 발끝과 같은 방향',
        en: 'Keep knees pointed same direction as feet',
        basis: Basis.source,
      ),
      // 🟩 Do not allow heels to raise off of platform, pushing with both heel and forefoot.
      (
        ko: '뒤꿈치와 앞꿈치로 함께 밀기',
        en: 'Push with both heel and forefoot',
        basis: Basis.source,
      ),
      // 🟩 Adjust seat and back support to accommodate near full range of motion without forcing hips to bend at waist.
      (
        ko: '시트·등받이를 가동범위에 맞춰 조절',
        en: 'Set seat and back support for near full range',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Do not allow heels to raise off of platform
      (
        ko: '뒤꿈치가 발판에서 뜨기',
        en: 'Heels lifting off the platform',
        basis: Basis.source,
      ),
    ],
  ),
  // 시티드 레그컬 (Seated Leg Curl)
  // 근육 🟩 ← Target: Hamstrings. Synergists: Gastrocnemius, Gracilis, Sartorius, Popliteus (Gracilis/Sartorius/Popliteus have no enum id; omitted)
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Hamstrings/LVSeatedLegCurl
  '시티드 레그컬': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Position back of seat so knees are aligned with fulcrum of lever.
      (
        ko: '무릎을 기계 회전축에 맞추기',
        en: 'Align knees with the lever\'s pivot',
        basis: Basis.source,
      ),
      // 🟩 Position lever pad so it makes contact with lowers leg just above ankles.
      (
        ko: '패드는 발목 바로 위에',
        en: 'Lever pad just above the ankles',
        basis: Basis.source,
      ),
      // 🟩 Return lever until knees are straight.
      (
        ko: '무릎이 펴질 때까지 되돌리기',
        en: 'Return until knees are straight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Secure lap pad on thighs just above knees.
      (
        ko: '무릎 위 허벅지 패드를 고정하지 않기',
        en: 'Not securing the lap pad above the knees',
        basis: Basis.source,
      ),
    ],
  ),
  // 라잉 레그컬 (Lying Leg Curl)
  // 근육 🟩 ← Target: Hamstrings. Synergists: Gastrocnemius, Sartorius, Gracilis, Popliteus (Sartorius/Gracilis/Popliteus have no enum id; omitted)
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Hamstrings/LVLyingLegCurl
  '라잉 레그컬': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Lie prone on bench with knees just beyond edge of bench and lower legs under lever pads.
      (
        ko: '무릎은 벤치 끝을 살짝 넘기기',
        en: 'Knees just beyond the bench edge',
        basis: Basis.source,
      ),
      // 🟩 Keep torso on bench to reduce hyperextension of lower back.
      (
        ko: '상체를 벤치에 붙여 허리 과신전 줄이기',
        en: 'Keep torso on bench to limit lower-back arching',
        basis: Basis.source,
      ),
      // 🟩 Lower lever pads until knees are straight.
      (
        ko: '무릎이 펴질 때까지 내리기',
        en: 'Lower until knees are straight',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Keep torso on bench to reduce hyperextension of lower back.
      (
        ko: '상체를 들어 허리를 꺾기',
        en: 'Lifting the torso and arching the lower back',
        basis: Basis.source,
      ),
    ],
  ),
  // 닐링 레그컬 (Kneeling Leg Curl)
  // 근육 🟩 ← Target: Hamstrings. Synergists: Gastrocnemius, Gracilis, Sartorius, Popliteus (Gracilis/Sartorius/Popliteus have no enum id; omitted)
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Hamstrings/LVKneelingLegCurl
  '닐링 레그컬': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Mount machine by placing supporting knee on horizontal pad and other leg under roller pad with knee against vertical pad.
      (
        ko: '받치는 무릎은 수평 패드, 운동하는 다리는 롤러 아래',
        en: 'Support knee on horizontal pad, working leg under roller',
        basis: Basis.source,
      ),
      // 🟩 Raise ankle to back of thigh by flexing knee.
      (
        ko: '발목을 허벅지 뒤로 끌어올리기',
        en: 'Raise ankle to back of thigh',
        basis: Basis.source,
      ),
      // 🟩 Lower ankle until knee is straight. Repeat. Continue with opposite leg.
      (
        ko: '무릎이 펴질 때까지 내리고 반대쪽도',
        en: 'Lower until straight, then switch legs',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 레그컬(ace:153 "Avoid arching your back during this movement")에서 옮김
      (ko: '허리를 젖힌다', en: 'Arching the low back', basis: Basis.adapted),
    ],
  ),
  // 스탠딩 레그컬 (Standing Leg Curl)
  // 근육 🟩 ← Target: Hamstrings. Synergists: Gastrocnemius, Sartorius, Gracilis (Sartorius/Gracilis have no enum id; omitted)
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Hamstrings/LVStandingLegCurl
  '스탠딩 레그컬': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.calves],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Position exercising leg with lever pad behind lower leg and upper pad in front of lower thigh.
      (
        ko: '패드는 종아리 뒤, 윗패드는 허벅지 아래 앞쪽',
        en: 'Lever pad behind lower leg, upper pad in front of lower thigh',
        basis: Basis.source,
      ),
      // 🟩 Stand with body weight shifted on foot of resting leg and raise foot of exercising leg slightly off of floor or platform.
      (
        ko: '쉬는 다리에 체중을 싣기',
        en: 'Shift body weight onto the resting leg',
        basis: Basis.source,
      ),
      // 🟩 Return lever until knee is straight. Repeat. Continue with opposite leg.
      (
        ko: '무릎이 펴질 때까지 되돌리고 반대쪽도',
        en: 'Return until knee is straight, then switch legs',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 레그컬(ace:153 "Avoid arching your back during this movement")에서 옮김
      (ko: '허리를 젖힌다', en: 'Arching the low back', basis: Basis.adapted),
    ],
  ),
  // 힙 쓰러스트 머신 (Hip Thrust Machine (Glute Drive))
  // 근육 🟦 ← (ExRx has no machine page; closest Barbell Hip Thrust) Target: Gluteus Maximus. Synergists: Quadriceps. Dynamic Stabilizers: Hamstrings. Stabilizers: Erector Spinae. Antagonist Stabilizers: Rectus Abdominis, Obliques
  // 출처: https://web.archive.org/web/20260403013537/https://exrx.net/WeightExercises/GluteusMaximus/BBHipThrust
  '힙 쓰러스트 머신': Move(
    primary: [Muscle.glutes],
    secondary: [Muscle.quads],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟦 Raise bar upward by extending hips until straight.
      (
        ko: '엉덩이를 펴서 몸통과 허벅지가 일직선이 될 때까지 올린다',
        en: 'Extend hips until straight',
        basis: Basis.adapted,
      ),
      // 🟦 Movement should occur through hip with torso rigid.
      (
        ko: '몸통은 단단히 고정하고 움직임은 고관절에서만',
        en: 'Move through the hip with a rigid torso',
        basis: Basis.adapted,
      ),
      // 🟦 Place feet on floor approximately shoulder width with knees bent.
      (
        ko: '발은 어깨너비, 무릎은 굽힌 채로',
        en: 'Feet about shoulder width, knees bent',
        basis: Basis.adapted,
      ),
    ],
    mistakes: [
      // 🟦 Avoid chest arching upward and anterior pelvic tilt, both producing spinal hyperextension.
      (
        ko: '가슴을 들어 올리거나 골반을 앞으로 기울여 허리를 과신전하기',
        en: 'Arching the chest up or tilting the pelvis forward, hyperextending the spine',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 글루트 킥백 머신 (Glute Kickback Machine (standing hip extension))
  // 근육 🟦 ← (Lever Standing Hip Extension) Target: Gluteus Maximus. Synergists: Hamstrings, Adductor Magnus. Stabilizers: Obliques, Erector Spinae, Quadratus Lumborum, Gluteus Medius, Gluteus Minimus. Antagonist Stabilizers: Rectus Abdominis
  // 출처: https://web.archive.org/web/20250424003811/https://exrx.net/WeightExercises/GluteusMaximus/LVStandingHipExtension
  '글루트 킥백 머신': Move(
    primary: [Muscle.glutes],
    secondary: [Muscle.hamstrings, Muscle.adductors],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Stand on platform facing to one side and grasp bar for support. Place leg nearest machine on padded roller while standing on other leg.
      (
        ko: '손잡이를 잡고 한쪽 다리로 지지한 채 반대 다리로 민다',
        en: 'Hold the bar for support and stand on the other leg',
        basis: Basis.source,
      ),
      // 🟩 Lower lever by extending hip.
      (
        ko: '고관절을 펴서 레버를 뒤·아래로 민다',
        en: 'Drive the lever by extending the hip',
        basis: Basis.source,
      ),
      // 🟩 Return until knee is higher than hip.
      (
        ko: '돌아올 때 무릎이 엉덩이보다 높아질 때까지 충분히 굽힌다',
        en: 'Return until the knee is higher than the hip',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      (
        ko: '허리를 젖혀 반동으로 다리를 차기',
        en: 'Arching the lower back to swing the leg',
        basis: Basis.none,
      ),
    ],
  ),
  // 힙 어브덕션 (Seated Hip Abduction Machine)
  // 근육 🟦 ← Target: Hip Abductors (listed below). Synergists: Gluteus Medius, Gluteus Minimus, Gluteus Maximus, Piriformis, Obturator externus. Stabilizers: No significant stabilizers
  // 출처: https://web.archive.org/web/20260306091312/https://exrx.net/WeightExercises/HipAbductor/LVSeatedHipAbduction
  '힙 어브덕션': Move(
    primary: [Muscle.glutes],
    secondary: [],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Lie back and grasp bars to sides.
      (
        ko: '등을 기대고 양옆 손잡이를 잡는다',
        en: 'Lie back and grasp the bars to the sides',
        basis: Basis.source,
      ),
      // 🟩 Move legs apart as far as possible. Return and repeat.
      (
        ko: '다리를 가능한 한 넓게 벌렸다가 돌아온다',
        en: 'Move legs apart as far as possible, then return',
        basis: Basis.source,
      ),
      // 🟩 If available, place heels on foot bars.
      (
        ko: '발판이 있으면 뒤꿈치를 올린다',
        en: 'Place heels on the foot bars if available',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Also see ROM Criteria and Spot Reduction Myth .
      (
        ko: '이 운동으로 허벅지 바깥 살만 빠진다고 기대하기(부분 감량은 근거 없음)',
        en: 'Expecting spot fat loss on the outer thigh',
        basis: Basis.source,
      ),
    ],
  ),
  // 스탠딩 힙 어브덕션 (Standing Hip Abduction Machine)
  // 근육 🟦 ← Target: Hip Abductors (listed below). Synergists: Tensor Fasciae Latae, Gluteus Medius, Gluteus Minimus. Stabilizers: Hip Abductors (opposite)
  // 출처: https://web.archive.org/web/20231121055450/https://exrx.net/WeightExercises/HipAbductor/LVStandHipAbduction
  '스탠딩 힙 어브덕션': Move(
    primary: [Muscle.glutes],
    secondary: [],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Adjust platform so lever fulcrum is same height as hip articulation.
      (
        ko: '레버 축을 고관절 높이에 맞춘다',
        en: 'Align the lever pivot with the hip joint',
        basis: Basis.source,
      ),
      // 🟩 Place outside of thigh against roller pad and shift body weight to opposite leg.
      (
        ko: '허벅지 바깥을 패드에 대고 체중은 반대 다리에',
        en: 'Outside of thigh on the pad, weight on the opposite leg',
        basis: Basis.source,
      ),
      // 🟩 Raise leg against roller pad to side by abduction hip. Return and repeat.
      (
        ko: '다리를 옆으로 들어 올렸다가 돌아온다',
        en: 'Raise the leg to the side, return and repeat',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      (
        ko: '상체를 옆으로 기울여 다리를 더 높이 올리려 하기',
        en: 'Leaning the torso sideways to lift the leg higher',
        basis: Basis.none,
      ),
    ],
  ),
  // 스탠딩 카프레이즈 머신 (Standing Calf Raise Machine)
  // 근육 🟩 ← Target: Gastrocnemius. Synergists: Soleus. Stabilizers: Trapezius, Upper; Trapezius, Middle; Levator Scapulae
  // 출처: https://web.archive.org/web/20250819125737/https://exrx.net/WeightExercises/Gastrocnemius/LVStandingCalfRaisePL
  '스탠딩 카프레이즈 머신': Move(
    primary: [Muscle.calves],
    secondary: [],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Position toes and balls of feet on calf block with arches and heels extending off.
      (
        ko: '발끝과 발볼만 블록에 올리고 뒤꿈치는 밖으로',
        en: 'Toes and balls of feet on the block, heels off',
        basis: Basis.source,
      ),
      // 🟩 Raise heels by extending ankles as high as possible.
      (
        ko: '뒤꿈치를 최대한 높이 들어 올린다',
        en: 'Raise heels as high as possible',
        basis: Basis.source,
      ),
      // 🟩 Keep knees straight throughout exercise or bend knees slightly only during stretch.
      (
        ko: '무릎은 끝까지 편 상태를 유지한다',
        en: 'Keep knees straight throughout',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟦 Quadriceps serve as synergist muscle if knees are bent slightly during stretch.
      (
        ko: '무릎을 굽혔다 펴며 다리 힘으로 밀어 올리기',
        en: 'Bending and extending the knees to push the weight up',
        basis: Basis.adapted,
      ),
    ],
  ),
  // 카프 익스텐션 (Seated Calf Extension (calf press machine))
  // 근육 🟩 ← Target: Gastrocnemius. Synergists: Soleus. Stabilizers: No significant stabilizers
  // 출처: https://web.archive.org/web/20260520125617/https://exrx.net/WeightExercises/Gastrocnemius/LVSeatedCalfExtension
  '카프 익스텐션': Move(
    primary: [Muscle.calves],
    secondary: [],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on seat and position forefeet on horizontal foot bar. Grasp handles to sides and straighten knees.
      (
        ko: '앞꿈치를 발판 가로대에 올리고 무릎을 편다',
        en: 'Forefeet on the foot bar, knees straight',
        basis: Basis.source,
      ),
      // 🟩 Push lever by extending ankles as far as possible.
      (
        ko: '발목을 최대한 펴서 민다',
        en: 'Push by extending ankles as far as possible',
        basis: Basis.source,
      ),
      // 🟩 Return by bending ankles until calves are stretched.
      (
        ko: '종아리가 늘어날 때까지 돌아온다',
        en: 'Return until calves are stretched',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 Reposition stance if feet slip.
      (
        ko: '발이 미끄러지는데 그대로 계속하기',
        en: 'Continuing while the feet slip',
        basis: Basis.source,
      ),
    ],
  ),
  // 머신 크런치 (Ab Crunch Machine)
  // 근육 🟩 ← Target: Rectus Abdominis. Synergists: Obliques. Stabilizers: Pectoralis Major, Sternal; Latissimus Dorsi; Teres Major; Deltoid, Posterior; Triceps, Long Head
  // 출처: https://web.archive.org/web/20260609063648/https://exrx.net/WeightExercises/RectusAbdominis/LVSeatedCrunch
  '머신 크런치': Move(
    primary: [Muscle.abs],
    secondary: [Muscle.obliques],
    primaryInterp: false,
    secondaryInterp: false,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Sit on machine with back and hips against back supports.
      (
        ko: '등과 엉덩이를 등받이에 붙이고 앉는다',
        en: 'Sit with back and hips against the supports',
        basis: Basis.source,
      ),
      // 🟩 With hips stationary, flex waist so elbows travel downward.
      (
        ko: '엉덩이는 고정하고 허리를 말아 팔꿈치를 아래로',
        en: 'Keep hips stationary and flex the waist so elbows travel down',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      (
        ko: '팔로 손잡이를 당겨 무게를 내리기',
        en: 'Pulling the handles down with the arms',
        basis: Basis.none,
      ),
      // 🟩 See Spot Reduction Myth .
      (
        ko: '이 운동으로 뱃살이 부분적으로 빠진다고 기대하기',
        en: 'Expecting spot fat loss on the belly',
        basis: Basis.source,
      ),
    ],
  ),
  // 로터리 토르소 (Rotary Torso Machine)
  // 근육 🟦 ← Target Obliques Synergists Psoas major Quadratus lumborum Iliocastalis lumborum Iliocastalis thoracis
  // 출처: https://web.archive.org/web/2025/https://exrx.net/WeightExercises/Obliques/LVTwist
  '로터리 토르소': Move(
    primary: [Muscle.obliques],
    secondary: [Muscle.hipFlexors, Muscle.lowerBack],
    primaryInterp: true,
    secondaryInterp: true,
    sites: ['ExRx.net'],
    cues: [
      // 🟩 Adjust range of motion setting on machine to one side.
      (
        ko: '시작 전 머신의 가동 범위를 한쪽으로 맞춘다',
        en: 'Set the machine\'s range-of-motion setting to one side before starting',
        basis: Basis.source,
      ),
      // 🟩 Sit with legs against padding. Place torso against pad and grasp handles.
      (
        ko: '다리를 패드에 붙이고 상체를 패드에 댄 채 손잡이를 잡는다',
        en: 'Sit with legs against the padding, torso against the pad, and grasp the handles',
        basis: Basis.source,
      ),
      // 🟩 Rotate torso through waist to opposite side. Return and repeat.
      (
        ko: '허리에서 상체를 반대쪽으로 돌렸다가 돌아온다',
        en: 'Rotate the torso through the waist to the opposite side, then return',
        basis: Basis.source,
      ),
      // 🟩 Adjust range of motion setting to opposite side and repeat in opposite direction.
      (
        ko: '한쪽이 끝나면 설정을 반대로 바꿔 반대 방향도 한다',
        en: 'Switch the range setting and repeat in the opposite direction',
        basis: Basis.source,
      ),
    ],
    mistakes: [
      // 🟩 See Spot Reduction Myth .
      (
        ko: '옆구리 살을 빼려는 목적으로만 하지 않기 (부분 감량은 근거 없음)',
        en: 'Don\'t rely on it to burn side fat - spot reduction is a myth',
        basis: Basis.source,
      ),
      // 🟦 Adjust range of motion setting to opposite side and repeat in opposite direction.
      (
        ko: '한 방향만 하고 끝내지 않기',
        en: 'Don\'t train only one direction',
        basis: Basis.adapted,
      ),
    ],
  ),
};

// 출처 열쇠 → 주소 (보관본이 있으면 함께):
// exrx:WeightTraining/Safety — ExRx.net — Weight Training Safety (Upright Row Safety)
//   https://exrx.net/WeightTraining/Safety
//   https://web.archive.org/web/20260520125526/https://exrx.net/WeightTraining/Safety
// exrx:PectoralSternal/BBBenchPress — ExRx.net — Barbell Bench Press
//   https://exrx.net/WeightExercises/PectoralSternal/BBBenchPress
//   https://web.archive.org/web/20260904055624/https://exrx.net/WeightExercises/PectoralSternal/BBBenchPress
// ace:5 — ACE Exercise Library — Chest Press
//   https://www.acefitness.org/resources/everyone/exercise-library/5/chest-press/
// exrx:PectoralClavicular/BBInclineBenchPress — ExRx.net — Barbell Incline Bench Press
//   https://exrx.net/WeightExercises/PectoralClavicular/BBInclineBenchPress
//   https://web.archive.org/web/20260202161856/https://exrx.net/WeightExercises/PectoralClavicular/BBInclineBenchPress
// ace:25 — ACE Exercise Library — Incline Chest Press
//   https://www.acefitness.org/resources/everyone/exercise-library/25/incline-chest-press/
// exrx:PectoralSternal/BBDeclineBenchPress — ExRx.net — Barbell Decline Bench Press
//   https://exrx.net/WeightExercises/PectoralSternal/BBDeclineBenchPress
//   https://web.archive.org/web/20260609063131/https://exrx.net/WeightExercises/PectoralSternal/BBDeclineBenchPress
// exrx:PectoralSternal/DBBenchPress — ExRx.net — Dumbbell Bench Press
//   https://exrx.net/WeightExercises/PectoralSternal/DBBenchPress
//   https://web.archive.org/web/20260918081352/https://exrx.net/WeightExercises/PectoralSternal/DBBenchPress
// ace:19 — ACE Exercise Library — Chest Press
//   https://www.acefitness.org/resources/everyone/exercise-library/19/chest-press/
// exrx:PectoralClavicular/DBInclineBenchPress — ExRx.net — Dumbbell Incline Bench Press
//   https://exrx.net/WeightExercises/PectoralClavicular/DBInclineBenchPress
//   https://web.archive.org/web/20260127130505/https://exrx.net/WeightExercises/PectoralClavicular/DBInclineBenchPress
// exrx:PectoralSternal/LVChestPress — ExRx.net — Lever Chest Press
//   https://exrx.net/WeightExercises/PectoralSternal/LVChestPress
//   https://web.archive.org/web/20260219093649/https://exrx.net/WeightExercises/PectoralSternal/LVChestPress
// ace:188 — ACE Exercise Library — Seated Chest Press
//   https://www.acefitness.org/resources/everyone/exercise-library/188/seated-chest-press/
// exrx:PectoralSternal/LVPecDeckFly — ExRx.net — Lever Isolateral Pec Deck Fly
//   https://exrx.net/WeightExercises/PectoralSternal/LVPecDeckFly
//   https://web.archive.org/web/20260729205508/https://exrx.net/WeightExercises/PectoralSternal/LVPecDeckFly
// exrx:PectoralSternal/CBStandingFly — ExRx.net — Cable Isolateral Standing Fly
//   https://exrx.net/WeightExercises/PectoralSternal/CBStandingFly
//   https://web.archive.org/web/20260206131348/https://exrx.net/WeightExercises/PectoralSternal/CBStandingFly
// exrx:PectoralSternal/BWPushup — ExRx.net — Push-up
//   https://exrx.net/WeightExercises/PectoralSternal/BWPushup
//   https://web.archive.org/web/20260828023119/https://exrx.net/WeightExercises/PectoralSternal/BWPushup
// ace:41 — ACE Exercise Library — Push-up
//   https://www.acefitness.org/resources/everyone/exercise-library/41/push-up/
// exrx:ErectorSpinae/BBDeadlift — ExRx.net — Barbell Deadlift
//   https://exrx.net/WeightExercises/ErectorSpinae/BBDeadlift
//   https://web.archive.org/web/20260314122608/https://exrx.net/WeightExercises/ErectorSpinae/BBDeadlift
// exrx:GluteusMaximus/BBDeadlift — ExRx.net — Barbell Deadlift
//   https://exrx.net/WeightExercises/GluteusMaximus/BBDeadlift
//   https://web.archive.org/web/20260326215720/https://exrx.net/WeightExercises/GluteusMaximus/BBDeadlift
// ace:6 — ACE Exercise Library — Deadlift
//   https://www.acefitness.org/resources/everyone/exercise-library/6/deadlift/
// ace:317 — ACE Exercise Library — Romanian Deadlift
//   https://www.acefitness.org/resources/everyone/exercise-library/317/romanian-deadlift/
// exrx:GluteusMaximus/BBStrBackStiffLegDeadlift — ExRx.net — Barbell Straight-back Stiff-leg Deadlift
//   https://exrx.net/WeightExercises/GluteusMaximus/BBStrBackStiffLegDeadlift
//   https://web.archive.org/web/20251112204611/https://exrx.net/WeightExercises/GluteusMaximus/BBStrBackStiffLegDeadlift
// exrx:Hamstrings/BBStrBackStrLegDeadlift — ExRx.net — Barbell Straight-back Straight-leg Deadlift
//   https://exrx.net/WeightExercises/Hamstrings/BBStrBackStrLegDeadlift
//   https://web.archive.org/web/20250302102526/https://exrx.net/WeightExercises/Hamstrings/BBStrBackStrLegDeadlift
// exrx:OlympicLifts/RomanianDeadlift — ExRx.net — Romanian Deadlift
//   https://exrx.net/WeightExercises/OlympicLifts/RomanianDeadlift
//   https://web.archive.org/web/20260625185205/https://exrx.net/WeightExercises/OlympicLifts/RomanianDeadlift
// exrx:LatissimusDorsi/CBFrontPulldown — ExRx.net — Cable Pulldown
//   https://exrx.net/WeightExercises/LatissimusDorsi/CBFrontPulldown
//   https://web.archive.org/web/20260125223729/https://exrx.net/WeightExercises/LatissimusDorsi/CBFrontPulldown
// ace:158 — ACE Exercise Library — Seated Lat Pulldown
//   https://www.acefitness.org/resources/everyone/exercise-library/158/seated-lat-pulldown/
// exrx:LatissimusDorsi/BWPullup — ExRx.net — Pull-up
//   https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup
//   https://web.archive.org/web/20260918081157/https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup
// ace:191 — ACE Exercise Library — Pull-ups
//   https://www.acefitness.org/resources/everyone/exercise-library/191/pull-ups/
// exrx:LatissimusDorsi/BWUnderhandChinup — ExRx.net — Chin-up
//   https://exrx.net/WeightExercises/LatissimusDorsi/BWUnderhandChinup
//   https://web.archive.org/web/20260220213224/https://exrx.net/WeightExercises/LatissimusDorsi/BWUnderhandChinup
// ace:190 — ACE Exercise Library — Chin-ups
//   https://www.acefitness.org/resources/everyone/exercise-library/190/chin-ups/
// exrx:BackGeneral/BBBentOverRow — ExRx.net — Barbell Bent-over Row
//   https://exrx.net/WeightExercises/BackGeneral/BBBentOverRow
//   https://web.archive.org/web/20260622144611/https://exrx.net/WeightExercises/BackGeneral/BBBentOverRow
// ace:12 — ACE Exercise Library — Bent-over Row
//   https://www.acefitness.org/resources/everyone/exercise-library/12/bent-over-row/
// exrx:BackGeneral/DBBentOverRow — ExRx.net — Dumbbell Bent-over Row
//   https://exrx.net/WeightExercises/BackGeneral/DBBentOverRow
//   https://web.archive.org/web/20260918081355/https://exrx.net/WeightExercises/BackGeneral/DBBentOverRow
// ace:126 — ACE Exercise Library — Single-arm Row
//   https://www.acefitness.org/resources/everyone/exercise-library/126/single-arm-row/
// exrx:BackGeneral/LVSeatedRow — ExRx.net — Lever Seated Row
//   https://exrx.net/WeightExercises/BackGeneral/LVSeatedRow
//   https://web.archive.org/web/20260217074254/https://exrx.net/WeightExercises/BackGeneral/LVSeatedRow
// ace:168 — ACE Exercise Library — Seated Row
//   https://www.acefitness.org/resources/everyone/exercise-library/168/seated-row/
// exrx:BackGeneral/CBSeatedRow — ExRx.net — Cable Seated Row
//   https://exrx.net/WeightExercises/BackGeneral/CBSeatedRow
//   https://web.archive.org/web/20260206131201/https://exrx.net/WeightExercises/BackGeneral/CBSeatedRow
// ace:48 — ACE Exercise Library — Seated Row
//   https://www.acefitness.org/resources/everyone/exercise-library/48/seated-row/
// exrx:BackGeneral/LVTBarRow — ExRx.net — Lever T-bar Row (plate loaded)
//   https://exrx.net/WeightExercises/BackGeneral/LVTBarRow
//   https://web.archive.org/web/20260730205245/https://exrx.net/WeightExercises/BackGeneral/LVTBarRow
// exrx:Hamstrings/BBGoodMorning — ExRx.net — Barbell Good-morning
//   https://exrx.net/WeightExercises/Hamstrings/BBGoodMorning
//   https://web.archive.org/web/20260717234215/https://exrx.net/WeightExercises/Hamstrings/BBGoodMorning
// exrx:OlympicLifts/PowerClean — ExRx.net — Power Clean
//   https://exrx.net/WeightExercises/OlympicLifts/PowerClean
//   https://web.archive.org/web/20260530025305/https://exrx.net/WeightExercises/OlympicLifts/PowerClean
// ace:125 — ACE Exercise Library — Power Clean
//   https://www.acefitness.org/resources/everyone/exercise-library/125/power-clean/
// exrx:Quadriceps/BBSquat — ExRx.net — Barbell Squat
//   https://exrx.net/WeightExercises/Quadriceps/BBSquat
//   https://web.archive.org/web/20260714093115/https://exrx.net/WeightExercises/Quadriceps/BBSquat
// ace:11 — ACE Exercise Library — Back Squat
//   https://www.acefitness.org/resources/everyone/exercise-library/11/back-squat/
// exrx:Quadriceps/BBFrontSquat — ExRx.net — Barbell Front Squat
//   https://exrx.net/WeightExercises/Quadriceps/BBFrontSquat
//   https://web.archive.org/web/20260717234405/https://exrx.net/WeightExercises/Quadriceps/BBFrontSquat
// exrx:Quadriceps/SLHackSquat — ExRx.net — Sled Hack Squat
//   https://exrx.net/WeightExercises/Quadriceps/SLHackSquat
//   https://web.archive.org/web/20260717234405/https://exrx.net/WeightExercises/Quadriceps/SLHackSquat
// exrx:Quadriceps/SL45LegPress — ExRx.net — Sled 45° Leg Press
//   https://exrx.net/WeightExercises/Quadriceps/SL45LegPress
//   https://web.archive.org/web/20260202161756/https://exrx.net/WeightExercises/Quadriceps/SL45LegPress
// ace:154 — ACE Exercise Library — Seated Leg Press
//   https://www.acefitness.org/resources/everyone/exercise-library/154/seated-leg-press/
// exrx:Quadriceps/LVLegExtension — ExRx.net — Lever Leg Extension
//   https://exrx.net/WeightExercises/Quadriceps/LVLegExtension
//   https://web.archive.org/web/20260717234405/https://exrx.net/WeightExercises/Quadriceps/LVLegExtension
// exrx:Hamstrings/LVLyingLegCurl — ExRx.net — Lever Lying Leg Curl
//   https://exrx.net/WeightExercises/Hamstrings/LVLyingLegCurl
//   https://web.archive.org/web/20260127130456/https://exrx.net/WeightExercises/Hamstrings/LVLyingLegCurl
// exrx:Hamstrings/LVSeatedLegCurl — ExRx.net — Lever Seated Leg Curl
//   https://exrx.net/WeightExercises/Hamstrings/LVSeatedLegCurl
//   https://web.archive.org/web/20260916033944/https://exrx.net/WeightExercises/Hamstrings/LVSeatedLegCurl
// ace:153 — ACE Exercise Library — Lying Hamstrings Curl
//   https://www.acefitness.org/resources/everyone/exercise-library/153/lying-hamstrings-curl/
// exrx:Quadriceps/DBLunge — ExRx.net — Dumbbell Lunge
//   https://exrx.net/WeightExercises/Quadriceps/DBLunge
//   https://web.archive.org/web/20260715231040/https://exrx.net/WeightExercises/Quadriceps/DBLunge
// exrx:Quadriceps/BWSingleLegSplitSquat — ExRx.net — Single Leg Split Squat
//   https://exrx.net/WeightExercises/Quadriceps/BWSingleLegSplitSquat
//   https://web.archive.org/web/20260812132116/https://exrx.net/WeightExercises/Quadriceps/BWSingleLegSplitSquat
// ace:366 — ACE Exercise Library — Bulgarian Split Squat
//   https://www.acefitness.org/resources/everyone/exercise-library/366/bulgarian-split-squat/
// exrx:GluteusMaximus/BBHipThrust — ExRx.net — Barbell Hip Thrust
//   https://exrx.net/WeightExercises/GluteusMaximus/BBHipThrust
//   https://web.archive.org/web/20260403013704/https://exrx.net/WeightExercises/GluteusMaximus/BBHipThrust
// ace:49 — ACE Exercise Library — Glute Bridge
//   https://www.acefitness.org/resources/everyone/exercise-library/49/glute-bridge/
// exrx:Gastrocnemius/LVStandingCalfRaise — ExRx.net — Lever Standing Calf Raise
//   https://exrx.net/WeightExercises/Gastrocnemius/LVStandingCalfRaise
//   https://web.archive.org/web/20230407071949/https://exrx.net/WeightExercises/Gastrocnemius/LVStandingCalfRaise
// exrx:HipFlexors/BWLyingLegRaise — ExRx.net — Lying Leg Raise (on bench)
//   https://exrx.net/WeightExercises/HipFlexors/BWLyingLegRaise
//   https://web.archive.org/web/20210619023658/https://exrx.net/WeightExercises/HipFlexors/BWLyingLegRaise
// exrx:DeltoidAnterior/BBMilitaryPress — ExRx.net — Barbell Military Press
//   https://exrx.net/WeightExercises/DeltoidAnterior/BBMilitaryPress
//   https://web.archive.org/web/20260312053832/https://exrx.net/WeightExercises/DeltoidAnterior/BBMilitaryPress
// ace:71 — ACE Exercise Library — Standing Shoulder Press
//   https://www.acefitness.org/resources/everyone/exercise-library/71/standing-shoulder-press/
// exrx:DeltoidAnterior/LVShoulderPress — ExRx.net — Lever Shoulder Press
//   https://exrx.net/WeightExercises/DeltoidAnterior/LVShoulderPress
//   https://web.archive.org/web/20230607121626/https://exrx.net/WeightExercises/DeltoidAnterior/LVShoulderPress
// ace:186 — ACE Exercise Library — Seated Shoulder Press
//   https://www.acefitness.org/resources/everyone/exercise-library/186/seated-shoulder-press/
// exrx:DeltoidAnterior/DBShoulderPress — ExRx.net — Dumbbell Shoulder Press
//   https://exrx.net/WeightExercises/DeltoidAnterior/DBShoulderPress
//   https://web.archive.org/web/20260202232933/https://exrx.net/WeightExercises/DeltoidAnterior/DBShoulderPress
// ace:43 — ACE Exercise Library — Seated Shoulder Press
//   https://www.acefitness.org/resources/everyone/exercise-library/43/seated-shoulder-press/
// exrx:DeltoidLateral/DBLateralRaise — ExRx.net — Dumbbell Lateral Raise
//   https://exrx.net/WeightExercises/DeltoidLateral/DBLateralRaise
//   https://web.archive.org/web/20260815202145/https://exrx.net/WeightExercises/DeltoidLateral/DBLateralRaise
// ace:26 — ACE Exercise Library — Lateral Raise
//   https://www.acefitness.org/resources/everyone/exercise-library/26/lateral-raise/
// exrx:DeltoidAnterior/DBFrontRaise — ExRx.net — Dumbbell Front Raise
//   https://exrx.net/WeightExercises/DeltoidAnterior/DBFrontRaise
//   https://web.archive.org/web/20260715231043/https://exrx.net/WeightExercises/DeltoidAnterior/DBFrontRaise
// ace:54 — ACE Exercise Library — Front Raise
//   https://www.acefitness.org/resources/everyone/exercise-library/54/front-raise/
// exrx:DeltoidPosterior/DBRearLateralRaise — ExRx.net — Dumbbell Rear Lateral Raise
//   https://exrx.net/WeightExercises/DeltoidPosterior/DBRearLateralRaise
//   https://web.archive.org/web/20260430002326/https://exrx.net/WeightExercises/DeltoidPosterior/DBRearLateralRaise
// exrx:DeltoidLateral/BBUprightRow — ExRx.net — Barbell Upright Row
//   https://exrx.net/WeightExercises/DeltoidLateral/BBUprightRow
//   https://web.archive.org/web/20260823090330/https://exrx.net/WeightExercises/DeltoidLateral/BBUprightRow
// exrx:TrapeziusUpper/BBShrug — ExRx.net — Barbell Shrug
//   https://exrx.net/WeightExercises/TrapeziusUpper/BBShrug
//   https://web.archive.org/web/20260406165424/https://exrx.net/WeightExercises/TrapeziusUpper/BBShrug
// ace:72 — ACE Exercise Library — Shrug
//   https://www.acefitness.org/resources/everyone/exercise-library/72/shrug/
// ace:75 — ACE Exercise Library — Standing Shrug
//   https://www.acefitness.org/resources/everyone/exercise-library/75/standing-shrug/
// exrx:Biceps/BBCurl — ExRx.net — Barbell Curl
//   https://exrx.net/WeightExercises/Biceps/BBCurl
//   https://web.archive.org/web/20260609063934/https://exrx.net/WeightExercises/Biceps/BBCurl
// ace:70 — ACE Exercise Library — Bicep Curl
//   https://www.acefitness.org/resources/everyone/exercise-library/70/bicep-curl/
// exrx:Biceps/DBCurl — ExRx.net — Dumbbell Curl
//   https://exrx.net/WeightExercises/Biceps/DBCurl
//   https://web.archive.org/web/20260715231046/https://exrx.net/WeightExercises/Biceps/DBCurl
// exrx:Brachioradialis/DBHammerCurl — ExRx.net — Dumbbell Hammer Curl
//   https://exrx.net/WeightExercises/Brachioradialis/DBHammerCurl
//   https://web.archive.org/web/20260703202908/https://exrx.net/WeightExercises/Brachioradialis/DBHammerCurl
// ace:10 — ACE Exercise Library — Hammer Curl
//   https://www.acefitness.org/resources/everyone/exercise-library/10/hammer-curl/
// exrx:Brachialis/BBPreacherCurl — ExRx.net — Barbell Preacher Curl
//   https://exrx.net/WeightExercises/Brachialis/BBPreacherCurl
//   https://web.archive.org/web/20260202161845/https://exrx.net/WeightExercises/Brachialis/BBPreacherCurl
// exrx:Biceps/CBCurl — ExRx.net — Cable Curl
//   https://exrx.net/WeightExercises/Biceps/CBCurl
//   https://web.archive.org/web/20260202161841/https://exrx.net/WeightExercises/Biceps/CBCurl
// ace:322 — ACE Exercise Library — Standing Bicep Curl
//   https://www.acefitness.org/resources/everyone/exercise-library/322/standing-bicep-curl/
// exrx:Triceps/DBTriExt — ExRx.net — Dumbbell Triceps Extension
//   https://exrx.net/WeightExercises/Triceps/DBTriExt
//   https://web.archive.org/web/20260316001351/https://exrx.net/WeightExercises/Triceps/DBTriExt
// ace:74 — ACE Exercise Library — Triceps Extension
//   https://www.acefitness.org/resources/everyone/exercise-library/74/triceps-extension/
// exrx:Triceps/CBPushdown — ExRx.net — Cable Pushdown
//   https://exrx.net/WeightExercises/Triceps/CBPushdown
//   https://web.archive.org/web/20260202161823/https://exrx.net/WeightExercises/Triceps/CBPushdown
// ace:185 — ACE Exercise Library — Triceps Pushdowns
//   https://www.acefitness.org/resources/everyone/exercise-library/185/triceps-pushdowns/
// exrx:Triceps/BWTriDip — ExRx.net — Triceps Dip
//   https://exrx.net/WeightExercises/Triceps/BWTriDip
//   https://web.archive.org/web/20260616202608/https://exrx.net/WeightExercises/Triceps/BWTriDip
// exrx:PectoralSternal/BWChestDip — ExRx.net — Chest Dip
//   https://exrx.net/WeightExercises/PectoralSternal/BWChestDip
//   https://web.archive.org/web/20260616202906/https://exrx.net/WeightExercises/PectoralSternal/BWChestDip
// exrx:Triceps/DBKickback — ExRx.net — Dumbbell Kickback
//   https://exrx.net/WeightExercises/Triceps/DBKickback
//   https://web.archive.org/web/20260715231027/https://exrx.net/WeightExercises/Triceps/DBKickback
// ace:55 — ACE Exercise Library — Triceps Kickback
//   https://www.acefitness.org/resources/everyone/exercise-library/55/triceps-kickback/
// exrx:RectusAbdominis/BWFrontPlank — ExRx.net — Front Plank
//   https://exrx.net/WeightExercises/RectusAbdominis/BWFrontPlank
//   https://web.archive.org/web/20260127130516/https://exrx.net/WeightExercises/RectusAbdominis/BWFrontPlank
// ace:32 — ACE Exercise Library — Front Plank
//   https://www.acefitness.org/resources/everyone/exercise-library/32/front-plank/
// exrx:Obliques/BWSidePlank — ExRx.net — Side Plank
//   https://exrx.net/WeightExercises/Obliques/BWSidePlank
//   https://web.archive.org/web/20250202084959/https://exrx.net/WeightExercises/Obliques/BWSidePlank
// ace:303 — ACE Exercise Library — Side Plank
//   https://www.acefitness.org/resources/everyone/exercise-library/303/side-plank/
// exrx:RectusAbdominis/BWCrunch — ExRx.net — Crunch
//   https://exrx.net/WeightExercises/RectusAbdominis/BWCrunch
//   https://web.archive.org/web/20260204034817/https://exrx.net/WeightExercises/RectusAbdominis/BWCrunch
// ace:52 — ACE Exercise Library — Crunch
//   https://www.acefitness.org/resources/everyone/exercise-library/52/crunch/
// exrx:RectusAbdominis/BWSitUp — ExRx.net — Sit-up
//   https://exrx.net/WeightExercises/RectusAbdominis/BWSitUp
//   https://web.archive.org/web/20260212192500/https://exrx.net/WeightExercises/RectusAbdominis/BWSitUp
// exrx:HipFlexors/BWHangingLegRaise — ExRx.net — Hanging Leg Raise
//   https://exrx.net/WeightExercises/HipFlexors/BWHangingLegRaise
//   https://web.archive.org/web/20260625122206/https://exrx.net/WeightExercises/HipFlexors/BWHangingLegRaise
// exrx:Obliques/DBRussianTwistBall — ExRx.net — Dumbbell Russian Twist (on stability ball)
//   https://exrx.net/WeightExercises/Obliques/DBRussianTwistBall
//   https://web.archive.org/web/20230316092004/https://exrx.net/WeightExercises/Obliques/DBRussianTwistBall
// ace:305 — ACE Exercise Library — V-twist
//   https://www.acefitness.org/resources/everyone/exercise-library/305/v-twist/
// concept2 — Concept2 — Muscles Used While Rowing
//   https://www.concept2.com/training/articles/rowing-muscles-used
// ace:306 — ACE Exercise Library — Burpee
//   https://www.acefitness.org/resources/everyone/exercise-library/306/burpee/
// exrx:DeltoidLateral/CBLateralRaise — ExRx.net — Cable Lateral Raise
//   https://exrx.net/WeightExercises/DeltoidLateral/CBLateralRaise
//   https://web.archive.org/web/20250824235813/https://exrx.net/WeightExercises/DeltoidLateral/CBLateralRaise
// exrx:DeltoidPosterior/LVRearLateralRaise — ExRx.net — Lever Isolateral Seated Reverse Fly (parallel grip)
//   https://exrx.net/WeightExercises/DeltoidPosterior/LVRearLateralRaise
//   https://web.archive.org/web/20260206131318/https://exrx.net/WeightExercises/DeltoidPosterior/LVRearLateralRaise
// exrx:DeltoidPosterior/CBStandingRearDeltRowRope — ExRx.net — Cable Standing Rear Delt Row (with rope)
//   https://exrx.net/WeightExercises/DeltoidPosterior/CBStandingRearDeltRowRope
//   https://web.archive.org/web/20230331040950/https://exrx.net/WeightExercises/DeltoidPosterior/CBStandingRearDeltRowRope
// exrx:TrapeziusUpper/DBShrug — ExRx.net — Dumbbell Shrug
//   https://exrx.net/WeightExercises/TrapeziusUpper/DBShrug
//   https://web.archive.org/web/20260206131427/https://exrx.net/WeightExercises/TrapeziusUpper/DBShrug
// exrx:Kettlebell/KBFarmersWalk — ExRx.net — Kettlebell Farmer's Walk
//   https://exrx.net/WeightExercises/Kettlebell/KBFarmersWalk
//   https://web.archive.org/web/20230607222301/https://exrx.net/WeightExercises/Kettlebell/KBFarmersWalk
// ace:359 — ACE Exercise Library — Farmer's Carry
//   https://www.acefitness.org/resources/everyone/exercise-library/359/farmer-s-carry/
// exrx:WristFlexors/BBWristCurl — ExRx.net — Barbell Wrist Curl
//   https://exrx.net/WeightExercises/WristFlexors/BBWristCurl
//   https://web.archive.org/web/20260120121953/https://exrx.net/WeightExercises/WristFlexors/BBWristCurl
// ace:30 — ACE Exercise Library — Wrist Curl - Flexion
//   https://www.acefitness.org/resources/everyone/exercise-library/30/wrist-curl-flexion/
// exrx:ErectorSpinae/BW45HyperextensionHips — ExRx.net — 45° Hyperextension (hands behind hips)
//   https://exrx.net/WeightExercises/ErectorSpinae/BW45HyperextensionHips
//   https://web.archive.org/web/20231108230123/https://exrx.net/WeightExercises/ErectorSpinae/BW45HyperextensionHips
// exrx:Hamstrings/BW45HyperextensionHips — ExRx.net — 45° Hyperextension (hands behind hips)
//   https://exrx.net/WeightExercises/Hamstrings/BW45HyperextensionHips
//   https://web.archive.org/web/20260624103842/https://exrx.net/WeightExercises/Hamstrings/BW45HyperextensionHips
// ace:9 — ACE Exercise Library — Supermans
//   https://www.acefitness.org/resources/everyone/exercise-library/9/supermans/
// ace:241 — ACE Exercise Library — Supine Bicycle Crunches
//   https://www.acefitness.org/resources/everyone/exercise-library/241/supine-bicycle-crunches/
// exrx:HipFlexors/BWVerticalLegRaise — ExRx.net — Vertical Leg Raise
//   https://exrx.net/WeightExercises/HipFlexors/BWVerticalLegRaise
//   https://web.archive.org/web/20250820083054/https://exrx.net/WeightExercises/HipFlexors/BWVerticalLegRaise
// exrx:HipAdductors/LVSeatedHipAdduction — ExRx.net — Lever Seated Hip Adduction
//   https://exrx.net/WeightExercises/HipAdductors/LVSeatedHipAdduction
//   https://web.archive.org/web/20260624103842/https://exrx.net/WeightExercises/HipAdductors/LVSeatedHipAdduction
// exrx:HipAdductors/CBHipAdduction — ExRx.net — Cable Hip Adduction
//   https://exrx.net/WeightExercises/HipAdductors/CBHipAdduction
//   https://web.archive.org/web/20260624103842/https://exrx.net/WeightExercises/HipAdductors/CBHipAdduction
// ace:104 — ACE Exercise Library — Standing Hip Adduction
//   https://www.acefitness.org/resources/everyone/exercise-library/104/standing-hip-adduction/
// ace:39 — ACE Exercise Library — Side Lying Hip Adduction
//   https://www.acefitness.org/resources/everyone/exercise-library/39/side-lying-hip-adduction/
// exrx:Soleus/LVSeatedCalfRaise — ExRx.net — Lever Seated Calf Raise
//   https://exrx.net/WeightExercises/Soleus/LVSeatedCalfRaise
//   https://web.archive.org/web/20221006140041/https://exrx.net/WeightExercises/Soleus/LVSeatedCalfRaise
// exrx:Gastrocnemius/SL45CalfRaise — ExRx.net — Sled 45° Calf Raise
//   https://exrx.net/WeightExercises/Gastrocnemius/SL45CalfRaise
//   https://web.archive.org/web/20240718231522/https://exrx.net/WeightExercises/Gastrocnemius/SL45CalfRaise
