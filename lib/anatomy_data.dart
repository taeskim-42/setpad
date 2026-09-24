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

/// 자세 팁 한 줄. [sourced] 가 거짓이면 출처 없이 덧붙인 말(🟦)이다.
typedef Cue = ({String ko, String en, bool sourced});

class Move {
  const Move({
    required this.primary,
    this.secondary = const [],
    required this.gear,
    required this.sites,
    required this.cues,
    required this.mistakes,
    this.names,
  });
  final List<Muscle> primary, secondary;

  /// 할 수 있는 기구(routineGear 의 값).
  final List<String> gear;

  /// 자세 팁 출처 사이트(화면 각주).
  final List<String> sites;
  final List<Cue> cues, mistakes;

  /// 이름 사전(exercises.dart) 밖 운동의 여덟 언어 이름. 사전 운동은 null.
  /// ko·en 밖의 이름은 조사자의 번역(🟦)이고 원어민 확인 전이다.
  final Exercise? names;
}

/// 한국어 이름 → 운동. 사전 운동의 열쇠는 exerciseKey 와 같다.
const moves = <String, Move>{
  // 벤치프레스 (Bench Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, Muscle.triceps],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/BBBenchPress "Dismount barbell from rack over upper chest"
      (
        ko: '바는 가슴 위쪽 위에서 랙에서 뺀다',
        en: 'Unrack the bar over your upper chest',
        sourced: true,
      ),
      // 🟩 ace:5 "Press the feet into the ground and the hips into the bench"
      (
        ko: '발로 바닥을, 엉덩이로 벤치를 누른다',
        en: 'Press your feet into the floor and your hips into the bench',
        sourced: true,
      ),
      // 🟩 ace:5 "Slowly lower the bar to the chest by allowing the elbows to bend out to the side"
      (
        ko: '팔꿈치를 옆으로 굽히며 바를 가슴까지 천천히 내린다',
        en: 'Lower the bar slowly to your chest, elbows bending out to the side',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/BBBenchPress "Press bar upward until arms are extended"
      (
        ko: '팔이 펴질 때까지 밀어 올린다',
        en: 'Press up until your arms are extended',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:PectoralSternal/BBBenchPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        sourced: true,
      ),
      // 🟦
      (
        ko: '가슴에서 바를 튕겨 올린다',
        en: 'Bouncing the bar off the chest',
        sourced: false,
      ),
    ],
  ),
  // 인클라인 벤치프레스 (Incline Bench Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Clavicular
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Sternal, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '인클라인 벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, Muscle.triceps],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Dismount barbell from rack over upper chest"
      (
        ko: '인클라인 벤치에 누워 바를 가슴 위쪽 위에서 뺀다',
        en: 'Lie on the incline bench and unrack over your upper chest',
        sourced: true,
      ),
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Lower weight to upper chest"
      (
        ko: '바를 가슴 위쪽으로 내린다',
        en: 'Lower the bar to your upper chest',
        sourced: true,
      ),
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Press bar until arms are extended"
      (
        ko: '팔이 펴질 때까지 밀어 올린다',
        en: 'Press until your arms are extended',
        sourced: true,
      ),
      // 🟦
      (
        ko: '어깨를 뒤·아래로 당겨 벤치에 붙인다',
        en: 'Pull your shoulders back and down against the bench',
        sourced: false,
      ),
    ],
    mistakes: [
      // 🟩 exrx:PectoralClavicular/BBInclineBenchPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        sourced: true,
      ),
      // 🟦
      (
        ko: '바를 가슴 아래쪽이나 배 쪽으로 내린다',
        en: 'Lowering the bar toward the lower chest or belly',
        sourced: false,
      ),
    ],
  ),
  // 디클라인 벤치프레스 (Decline Bench Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '디클라인 벤치프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, Muscle.triceps],
    gear: ['barbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Lie supine on decline bench with feet under leg brace"
      (
        ko: '다리를 받침에 걸고 디클라인 벤치에 눕는다',
        en: 'Lie on the decline bench with your feet under the leg brace',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Lower weight to chest"
      (ko: '바를 가슴으로 내린다', en: 'Lower the bar to your chest', sourced: true),
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Press bar until arms are extended"
      (
        ko: '팔이 펴질 때까지 밀어 올린다',
        en: 'Press until your arms are extended',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:PectoralSternal/BBDeclineBenchPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        sourced: true,
      ),
      // 🟦
      (
        ko: '바를 떨어뜨리듯 빠르게 내린다',
        en: 'Letting the bar drop fast instead of lowering it under control',
        sourced: false,
      ),
    ],
  ),
  // 덤벨 프레스 (Dumbbell Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '덤벨 프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, Muscle.triceps],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/DBBenchPress "Kick weights to shoulder and lie back"
      (
        ko: '덤벨을 허벅지에 올려 두었다가 무릎으로 밀어 올리며 눕는다',
        en: 'Rest the dumbbells on your thighs and kick them up as you lie back',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/DBBenchPress "Press dumbbells up with elbows to sides until arms are extended"
      (
        ko: '팔꿈치를 옆으로 두고 팔이 펴질 때까지 민다',
        en: 'Press with elbows to the sides until your arms are extended',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/DBBenchPress "Lower weight to sides of chest until slight stretch is felt in chest or shoulder"
      (
        ko: '가슴이나 어깨가 살짝 늘어나는 곳까지 내린다',
        en: 'Lower until you feel a slight stretch in your chest or shoulders',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/DBBenchPress "traveling inward over each shoulder at top"
      (
        ko: '올라가며 덤벨이 어깨 위로 모이는 약한 호를 그린다',
        en: 'Let the dumbbells travel in a slight arc, coming in over the shoulders at the top',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:19 "Gently touch the dumbbells to your chest without bouncing"
      (
        ko: '가슴에서 덤벨을 튕긴다',
        en: 'Bouncing the dumbbells off your chest',
        sourced: true,
      ),
      // 🟩 ace:19 "Maintain a neutral wrist position"
      (ko: '손목이 뒤로 꺾인다', en: 'Letting the wrists bend back', sourced: true),
    ],
  ),
  // 인클라인 덤벨 프레스 (Incline Dumbbell Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Clavicular
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Sternal, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '인클라인 덤벨 프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, Muscle.triceps],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralClavicular/DBInclineBenchPress "Position dumbbells to sides of chest with upper arm under each dumbbell"
      (
        ko: '덤벨을 가슴 위쪽 옆에서 시작한다',
        en: 'Start with the dumbbells at the sides of your upper chest',
        sourced: true,
      ),
      // 🟩 exrx:PectoralClavicular/DBInclineBenchPress "Press dumbbells up with elbows to sides until arms are extended"
      (
        ko: '팔꿈치를 옆으로 두고 팔이 펴질 때까지 민다',
        en: 'Press with elbows to the sides until your arms are extended',
        sourced: true,
      ),
      // 🟩 exrx:PectoralClavicular/DBInclineBenchPress "Lower weight to sides of upper chest until slight stretch is felt in chest or shoulder"
      (
        ko: '가슴 위쪽이 살짝 늘어나는 곳까지 내린다',
        en: 'Lower to the sides of your upper chest until you feel a slight stretch',
        sourced: true,
      ),
      // 🟩 ace:25 "Your head, shoulders, butt and feet should make contact with the bench and floor/riser throughout the exercise"
      (
        ko: '머리·어깨·엉덩이·발은 벤치와 바닥에 닿은 채로',
        en: 'Keep head, shoulders, hips and feet in contact with the bench and floor',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:25 "Gently touch the dumbbells to your chest without bouncing"
      (
        ko: '가슴에서 덤벨을 튕긴다',
        en: 'Bouncing the dumbbells off your chest',
        sourced: true,
      ),
      // 🟩 ace:25 "Maintain a neutral wrist position"
      (ko: '손목이 뒤로 꺾인다', en: 'Letting the wrists bend back', sourced: true),
    ],
  ),
  // 체스트 프레스 (Chest Press)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '체스트 프레스': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, Muscle.triceps],
    gear: ['machine'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/LVChestPress "Sit on seat with chest approximately height of horizontal handles"
      (
        ko: '손잡이가 가슴 높이에 오게 좌석을 맞춘다',
        en: 'Set the seat so the handles are at chest height',
        sourced: true,
      ),
      // 🟩 ace:188 "Continue pressing until your elbows are fully extended, but not locked"
      (
        ko: '팔이 펴질 때까지 밀되 팔꿈치를 잠그지 않는다',
        en: 'Press until your arms are extended, without locking the elbows',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/LVChestPress "Return weight until chest muscles are slightly stretched"
      (
        ko: '가슴이 살짝 늘어나는 곳까지 되돌린다',
        en: 'Return until your chest is slightly stretched',
        sourced: true,
      ),
      // 🟩 ace:188 "Depress and retract your scapulae (pull shoulders back and down)"
      (
        ko: '어깨를 뒤·아래로 당긴 채 유지한다',
        en: 'Keep your shoulders pulled back and down',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:188 "avoid arching your back throughout the exercise"
      (ko: '허리를 젖힌다', en: 'Arching the low back', sourced: true),
      // 🟩 ace:188 "Your shoulder blades should continue to make contact with the backrest and not round or bend forward"
      (
        ko: '견갑골이 등받이에서 떨어지며 어깨가 앞으로 말린다',
        en: 'Letting the shoulder blades leave the backrest and round forward',
        sourced: true,
      ),
    ],
  ),
  // 펙덱 플라이 (Pec Deck Fly)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Coracobrachialis, Pectoralis Minor, Serratus Anterior
  '펙덱 플라이': Move(
    primary: [Muscle.chest],
    gear: ['machine'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/LVPecDeckFly "Place forearms on padded lever"
      (
        ko: '등을 패드에 붙이고 팔뚝을 레버 패드에 댄다',
        en: 'Sit with your back on the pad and forearms on the padded levers',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/LVPecDeckFly "Push levers together"
      (ko: '레버를 가운데로 모은다', en: 'Push the levers together', sourced: true),
      // 🟩 exrx:PectoralSternal/LVPecDeckFly "Return until chest muscles are stretched"
      (
        ko: '가슴이 늘어나는 곳까지 되돌린다',
        en: 'Return until your chest is stretched',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '되돌릴 때 레버가 반동으로 뒤로 튕겨 나간다',
        en: 'Letting the levers fly back with momentum',
        sourced: false,
      ),
      // 🟦
      (ko: '어깨가 으쓱 올라간다', en: 'Shrugging the shoulders up', sourced: false),
    ],
  ),
  // 케이블 크로스오버 (Cable Crossover)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Pectoralis Minor, Rhomboids, Levator Scapulae, Latissimus Dorsi, Coracobrachialis
  '케이블 크로스오버': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.upperBack, Muscle.lats],
    gear: ['cable'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/CBStandingFly "Bend over slightly by flexing hips and knees"
      (
        ko: '높은 도르래 두 개 사이에 서서 엉덩이·무릎을 살짝 굽혀 숙인다',
        en: 'Stand between two high pulleys and bend forward slightly at hips and knees',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/CBStandingFly "Bring cable attachments together in hugging motion with elbows in fixed position"
      (
        ko: '팔꿈치 각도를 고정한 채 껴안듯 손을 모은다',
        en: 'Keep the elbows fixed and bring the handles together in a hugging motion',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/CBStandingFly "Return to starting position until chest muscles are stretched"
      (
        ko: '가슴이 늘어나는 곳까지 되돌린다',
        en: 'Return until your chest is stretched',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '팔꿈치를 굽혔다 폈다 하며 미는 동작이 된다',
        en: 'Bending and straightening the elbows so it turns into a press',
        sourced: false,
      ),
      // 🟩 exrx:PectoralSternal/CBStandingFly "struggling with backward pull of cables"
      (
        ko: '무거운 무게에 몸이 뒤로 끌려간다',
        en: 'Getting pulled backward by the cables under heavy load',
        sourced: true,
      ),
    ],
  ),
  // 푸시업 (Push Up)
  // 근육 🟩 주동 ← ExRx Target: Pectoralis Major, Sternal
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Anterior, Triceps Brachii, Coracobrachialis
  '푸시업': Move(
    primary: [Muscle.chest],
    secondary: [Muscle.frontDelts, Muscle.triceps],
    gear: ['bodyweight'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:PectoralSternal/BWPushup "hands slightly wider than shoulder width"
      (
        ko: '손은 어깨너비보다 조금 넓게',
        en: 'Hands slightly wider than shoulder width',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/BWPushup "Keeping body straight"
      (
        ko: '머리부터 발까지 몸을 곧게 유지한다',
        en: 'Keep your body straight from head to feet',
        sourced: true,
      ),
      // 🟩 ace:41 "Stiffen your torso by contracting your core/abdominal muscles"
      (
        ko: '복근·엉덩이·허벅지에 힘을 줘 몸통을 단단히 한다',
        en: 'Brace your abs, glutes and thighs to stiffen your torso',
        sourced: true,
      ),
      // 🟩 ace:41 "think about pushing the floor away from you"
      (
        ko: '바닥을 밀어낸다는 느낌으로 올라온다',
        en: 'Think about pushing the floor away',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:41 "Do not allow your low back to sag or your hips to hike upwards"
      (
        ko: '허리가 처지거나 엉덩이가 솟는다',
        en: 'Letting the low back sag or the hips hike up',
        sourced: true,
      ),
      // 🟩 ace:41 "Continue to lower yourself until your chest or chin touch the mat/floor"
      (ko: '끝까지 내려가지 않는다', en: 'Not lowering all the way', sourced: true),
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
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:ErectorSpinae/BBDeadlift "Keep bar close to body"
      (ko: '바를 몸 가까이 둔다', en: 'Keep the bar close to your body', sourced: true),
      // 🟩 exrx:ErectorSpinae/BBDeadlift "keep hips low, shoulders high, arms and back straight"
      (
        ko: '엉덩이는 낮게, 어깨는 높게, 팔과 등은 곧게',
        en: 'Hips low, shoulders high, arms and back straight',
        sourced: true,
      ),
      // 🟩 exrx:ErectorSpinae/BBDeadlift "Knees should point same direction as feet throughout movement"
      (
        ko: '무릎은 발끝과 같은 방향을 향한다',
        en: 'Knees point the same way as your feet',
        sourced: true,
      ),
      // 🟩 exrx:ErectorSpinae/BBDeadlift "Lift bar by extending hips and knees to full extension"
      (
        ko: '엉덩이와 무릎을 끝까지 펴서 선다',
        en: 'Stand up by fully extending hips and knees',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:ErectorSpinae/BBDeadlift "arms and back straight"
      (ko: '등이 굽은 채 끌어올린다', en: 'Pulling with a rounded back', sourced: true),
      // 🟩 ace:6 "the glutes and the back of the thighs should feel the work, NOT the back"
      (
        ko: '엉덩이·허벅지 뒤가 아니라 허리에 힘이 몰린다',
        en: 'Feeling it mainly in the low back instead of the glutes and hamstrings',
        sourced: true,
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
    secondary: [Muscle.adductors],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:317 "keep a slight bend in both knees and a straight back"
      (
        ko: '무릎은 살짝 굽히고 등은 곧게 편 채 시작한다',
        en: 'Start with a slight knee bend and a straight back',
        sourced: true,
      ),
      // 🟩 exrx:OlympicLifts/RomanianDeadlift "tracing front contour of legs through downward motion"
      (
        ko: '엉덩이를 뒤로 밀며 바를 다리 앞선을 따라 내린다',
        en: 'Push your hips back and slide the bar down along the front of your legs',
        sourced: true,
      ),
      // 🟩 ace:317 "until feeling some tension along the back of the legs"
      (
        ko: '허벅지 뒤가 당기는 곳까지만 내린다',
        en: 'Lower only until you feel tension along the back of your legs',
        sourced: true,
      ),
      // 🟩 ace:317 "push the heels into the floor and pull the knees backwards, keeping the bar very close to the body"
      (
        ko: '발뒤꿈치로 바닥을 밀며 바를 몸 가까이 붙여 일어선다',
        en: 'Drive your heels into the floor and keep the bar close as you stand',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:OlympicLifts/RomanianDeadlift "keep arms and back straight and chest high"
      (ko: '등이 굽는다', en: 'Letting the back round', sourced: true),
      // 🟩 ace:317 "keeping the bar very close to the body"
      (
        ko: '바가 다리에서 멀어진다',
        en: 'Letting the bar drift away from your legs',
        sourced: true,
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
      Muscle.rearDelts,
    ],
    gear: ['cable'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:158 "adjusting the thigh pad to fit firmly against the top of your thighs"
      (
        ko: '허벅지 패드를 허벅지에 밀착시킨다',
        en: 'Lock your thighs under the pad',
        sourced: true,
      ),
      // 🟩 ace:158 "initiate the downward pull by first depressing (lower) your scapulae"
      (
        ko: '어깨를 먼저 내린 다음 바를 당긴다',
        en: 'Set your shoulders down first, then pull',
        sourced: true,
      ),
      // 🟩 exrx:LatissimusDorsi/CBFrontPulldown "Pull down cable bar to upper chest"
      (
        ko: '팔꿈치를 바닥 쪽으로 끌어내리며 바를 가슴 위쪽으로',
        en: 'Drive your elbows down and pull the bar to your upper chest',
        sourced: true,
      ),
      // 🟩 exrx:LatissimusDorsi/CBFrontPulldown "Return until arms and shoulders are fully extended"
      (
        ko: '팔과 어깨가 끝까지 펴질 때까지 되돌린다',
        en: 'Return until arms and shoulders are fully extended',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:158 "Avoid any additional backwards lean during the pull movement"
      (
        ko: '당기면서 몸을 뒤로 더 젖힌다',
        en: 'Leaning further back as you pull',
        sourced: true,
      ),
      // 🟩 exrx:LatissimusDorsi/CBFrontPulldown "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        sourced: true,
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
      Muscle.rearDelts,
    ],
    gear: ['bodyweight'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:191 "palms facing away from you"
      (
        ko: '손바닥이 앞을 보게 바를 잡는다',
        en: 'Grip the bar with palms facing away',
        sourced: true,
      ),
      // 🟩 ace:191 "Depress and retract your scapulae (pull shoulders back and down)"
      (
        ko: '어깨를 뒤·아래로 내린 상태를 유지한다',
        en: 'Keep your shoulders pulled back and down',
        sourced: true,
      ),
      // 🟩 exrx:LatissimusDorsi/BWPullup "Pull body up until chin is above bar"
      (
        ko: '턱이 바를 넘을 때까지 당긴다',
        en: 'Pull until your chin is above the bar',
        sourced: true,
      ),
      // 🟩 exrx:LatissimusDorsi/BWPullup "Lower body until arms and shoulders are fully extended"
      (
        ko: '팔과 어깨가 다 펴질 때까지 내려온다',
        en: 'Lower until arms and shoulders are fully extended',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:191 "avoid swinging your body during your upward pull"
      (ko: '몸을 흔들어 반동으로 올라간다', en: 'Swinging to use momentum', sourced: true),
      // 🟩 exrx:LatissimusDorsi/BWPullup "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        sourced: true,
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
      Muscle.rearDelts,
      Muscle.chest,
    ],
    gear: ['bodyweight'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "grasp bar with underhand shoulder width grip"
      (
        ko: '손바닥이 나를 보게 어깨너비로 잡는다',
        en: 'Grip shoulder width with palms facing you',
        sourced: true,
      ),
      // 🟩 ace:190 "your abdominal muscles to stabilize your spine"
      (
        ko: '복근에 힘을 줘 몸통을 고정한다',
        en: 'Brace your abs to steady your spine',
        sourced: true,
      ),
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "Pull body up until elbows are to sides"
      (
        ko: '팔꿈치가 옆구리에 올 때까지 당긴다',
        en: 'Pull until your elbows reach your sides',
        sourced: true,
      ),
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "Lower body until arms and shoulders are fully extended"
      (
        ko: '팔과 어깨가 다 펴질 때까지 내려온다',
        en: 'Lower until arms and shoulders are fully extended',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:190 "avoid swinging your body during your upward pull"
      (ko: '몸을 흔들어 반동으로 올라간다', en: 'Swinging to use momentum', sourced: true),
      // 🟩 exrx:LatissimusDorsi/BWUnderhandChinup "Lower body until arms and shoulders are fully extended"
      (ko: '반만 내려온다', en: 'Stopping halfway on the way down', sourced: true),
    ],
  ),
  // 바벨로우 (Barbell Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '바벨로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    secondary: [Muscle.rearDelts, Muscle.biceps, Muscle.forearms, Muscle.chest],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/BBBentOverRow "Bend knees slightly and bend over bar with back straight"
      (
        ko: '무릎을 살짝 굽히고 등을 곧게 편 채 숙인다',
        en: 'Bend your knees slightly and hinge over with a straight back',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/BBBentOverRow "Pull bar to upper waist"
      (
        ko: '바를 윗배 쪽으로 당긴다',
        en: 'Pull the bar to your upper waist',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/BBBentOverRow "Return until arms are extended and shoulders are stretched downward"
      (
        ko: '팔이 펴지고 어깨가 아래로 늘어날 때까지 내린다',
        en: 'Lower until your arms are straight and your shoulders stretch down',
        sourced: true,
      ),
      // 🟩 ace:12 "keep the back flat as the bar is pulled towards the belly button"
      (
        ko: '당기는 내내 등을 평평하게',
        en: 'Keep your back flat throughout',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/BBBentOverRow "Knees are bent in effort to keep low back straight"
      (ko: '허리가 둥글게 말린다', en: 'Rounding the low back', sourced: true),
      // 🟦
      (
        ko: '상체를 들어 올리며 반동으로 당긴다',
        en: 'Raising the torso to heave the bar up',
        sourced: false,
      ),
    ],
  ),
  // 덤벨로우 (Dumbbell Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '덤벨로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    secondary: [Muscle.rearDelts, Muscle.biceps, Muscle.forearms, Muscle.chest],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/DBBentOverRow "placing knee and hand of supporting arm on bench"
      (
        ko: '한쪽 무릎과 손을 벤치에 올려 몸을 받친다',
        en: 'Support yourself with one knee and hand on the bench',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/DBBentOverRow "Torso should be close to horizontal"
      (
        ko: '상체는 바닥과 거의 수평으로',
        en: 'Keep your torso close to horizontal',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/DBBentOverRow "until it makes contact with ribs"
      (
        ko: '덤벨이 옆구리에 닿을 때까지 당긴다',
        en: 'Pull the dumbbell up until it touches your ribs',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/DBBentOverRow "Return until arm is extended and shoulder is stretched downward"
      (
        ko: '팔이 펴지고 어깨가 아래로 늘어날 때까지 내린다',
        en: 'Lower until the arm is straight and the shoulder stretches down',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/DBBentOverRow "do not rotate torso in effort to throw weight up"
      (
        ko: '몸통을 비틀어 덤벨을 던지듯 올린다',
        en: 'Twisting the torso to throw the weight up',
        sourced: true,
      ),
      // 🟩 ace:126 "Your back should be flat"
      (ko: '등이 굽는다', en: 'Letting the back round', sourced: true),
    ],
  ),
  // 시티드 로우 (Seated Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '시티드 로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    secondary: [Muscle.rearDelts, Muscle.biceps, Muscle.forearms, Muscle.chest],
    gear: ['machine'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/LVSeatedRow "Sit on seat and position chest against pad"
      (
        ko: '가슴을 패드에 대고 앉는다',
        en: 'Sit with your chest against the pad',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/LVSeatedRow "Pull lever back until elbows are behind back and shoulders are pulled back"
      (
        ko: '팔꿈치가 등 뒤로 갈 때까지 당기며 어깨를 뒤로',
        en: 'Pull until your elbows pass your back and your shoulders draw back',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/LVSeatedRow "lift chest slightly and pull shoulder blades together"
      (
        ko: '끝에서 가슴을 살짝 들고 견갑골을 모은다',
        en: 'At the end, lift your chest slightly and squeeze your shoulder blades together',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/LVSeatedRow "Return until arms are extended and shoulders are stretched forward"
      (
        ko: '팔이 펴지고 어깨가 앞으로 늘어날 때까지 되돌린다',
        en: 'Return until arms are extended and shoulders stretch forward',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:168 "Avoid leaning back and arching your low back"
      (ko: '몸을 뒤로 젖혀 당긴다', en: 'Leaning back to pull', sourced: true),
      // 🟩 ace:168 "maintain a neutral wrist position"
      (ko: '손목이 꺾인다', en: 'Letting the wrists bend', sourced: true),
    ],
  ),
  // 케이블 로우 (Cable Row)
  // 근육 🟦 주동 ← ExRx Target: Back, General
  //      🟩 보조 ← ExRx Synergists: Erector Spinae, Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '케이블 로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    secondary: [
      Muscle.lowerBack,
      Muscle.rearDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.chest,
    ],
    gear: ['cable'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/CBSeatedRow "positioning knees with slight bend"
      (
        ko: '발을 발판에 대고 무릎을 살짝 굽힌다',
        en: 'Feet on the platform, knees slightly bent',
        sourced: true,
      ),
      // 🟩 ace:48 "pulling the elbows backwards close to the rib cage until the handle touches the front of the stomach"
      (
        ko: '팔꿈치를 갈비뼈 가까이 붙여 손잡이를 배 앞까지 당긴다',
        en: 'Pull the handle to your stomach with elbows close to your ribs',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/CBSeatedRow "Pull shoulders back and push chest forward"
      (
        ko: '당기며 가슴을 들고 어깨를 뒤로',
        en: 'Lift your chest and draw your shoulders back as you pull',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/CBSeatedRow "Begin with light weight and add additional weight gradually to allow lower back adequate adaptation"
      (
        ko: '가볍게 시작해 허리가 적응할 시간을 준다',
        en: 'Start light so your low back can adapt',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/CBSeatedRow "Do not pause or bounce at bottom of lift"
      (
        ko: '앞으로 뻗은 자리에서 멈추거나 튕긴다',
        en: 'Pausing or bouncing at the stretched position',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/CBSeatedRow "Do not lower weight beyond mild stretch"
      (
        ko: '가벼운 스트레칭을 넘어 앞으로 깊이 숙인다',
        en: 'Reaching forward past a mild stretch',
        sourced: true,
      ),
    ],
  ),
  // 티바로우 (T-Bar Row)
  // 근육 🟦 주동 ← ExRx Target: General, Back
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Trapezius, Lower, Rhomboids, Latissimus Dorsi, Teres Major, Deltoid, Posterior, Infraspinatus, Teres Minor, Brachialis, Brachioradialis, Pectoralis Major, Sternal
  // "Back, General" 을 광배근·등 중앙으로 옮긴 것은 🟦 (ExRx 는 등 전체를 하나의 target 으로 적는다).
  '티바로우': Move(
    primary: [Muscle.lats, Muscle.upperBack],
    secondary: [Muscle.rearDelts, Muscle.biceps, Muscle.forearms, Muscle.chest],
    gear: ['machine', 'barbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:BackGeneral/LVTBarRow "Bend knees slightly and bend over lever handles with back straight"
      (
        ko: '무릎을 살짝 굽히고 등을 곧게 편 채 숙인다',
        en: 'Bend your knees slightly and hinge over with a straight back',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/LVTBarRow "Pull lever up to torso"
      (
        ko: '손잡이를 몸통 쪽으로 당긴다',
        en: 'Pull the handles to your torso',
        sourced: true,
      ),
      // 🟩 exrx:BackGeneral/LVTBarRow "Return until arms are extended and shoulders are stretched downward"
      (
        ko: '팔이 펴지고 어깨가 아래로 늘어날 때까지 내린다',
        en: 'Lower until arms are straight and shoulders stretch down',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:BackGeneral/LVTBarRow "Keep low back straight"
      (ko: '허리가 둥글게 말린다', en: 'Rounding the low back', sourced: true),
      // 🟩 exrx:BackGeneral/LVTBarRow "Lighten load if torso raises beyond 45 degrees in order to complete repetition"
      (
        ko: '다 못 들어 상체를 45°보다 더 세운다 — 무게를 줄일 때',
        en: 'Raising the torso past 45° to finish a rep — lighten the load instead',
        sourced: true,
      ),
    ],
  ),
  // 굿모닝 (Good Morning)
  // 근육 🟩 주동 ← ExRx Target: Hamstrings
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus
  '굿모닝': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.glutes, Muscle.adductors],
    gear: ['barbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Hamstrings/BBGoodMorning "Position barbell on back of shoulders"
      (
        ko: '바를 어깨 뒤에 얹는다',
        en: 'Rest the bar on the back of your shoulders',
        sourced: true,
      ),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Keeping back straight, bend hips to lower torso forward until parallel to floor"
      (
        ko: '등을 곧게 편 채 엉덩이를 굽혀 상체를 바닥과 평행까지 숙인다',
        en: 'Keeping your back straight, hinge at the hips until your torso is parallel to the floor',
        sourced: true,
      ),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Do not lower weight beyond mild stretch through hamstrings"
      (
        ko: '햄스트링이 가볍게 늘어나는 곳까지만',
        en: 'Go only as far as a mild hamstring stretch',
        sourced: true,
      ),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Begin with very light weight"
      (
        ko: '아주 가벼운 무게로 시작한다',
        en: 'Start with a very light weight',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Hamstrings/BBGoodMorning "Throughout lift, keep back and knees straight"
      (ko: '등이 굽는다', en: 'Letting the back round', sourced: true),
      // 🟩 exrx:Hamstrings/BBGoodMorning "Full range of motion will vary from person to person depending on flexibility"
      (
        ko: '유연성보다 깊이 내려간다',
        en: 'Going deeper than your flexibility allows',
        sourced: true,
      ),
    ],
  ),
  // 파워클린 (Power Clean)
  // 근육 출처: exrx:OlympicLifts/PowerClean
  // ExRx 는 근육 목록 없이 관절 동작만 적었다: 엉덩이·무릎 신전, 발목 저측굴곡, 어깨 외전·굴곡·외회전, 견갑 거상·상방회전, 팔꿈치 굴곡, 척추 신전(정적). 이 동작을 부위로 옮긴 것은 🟦. ACE 는 "Full Body/Integrated" 로만 적었다.
  // 기술 동작이다 — 처음 배울 때는 코치에게 배우길 권한다(🟦).
  '파워클린': Move(
    primary: [Muscle.glutes, Muscle.hamstrings, Muscle.quads, Muscle.traps],
    secondary: [
      Muscle.calves,
      Muscle.sideDelts,
      Muscle.frontDelts,
      Muscle.biceps,
    ],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:OlympicLifts/PowerClean "Position shoulders over bar with back arched tightly"
      (
        ko: '어깨를 바 위에 두고 등을 단단히 편다',
        en: 'Shoulders over the bar, back set tight',
        sourced: true,
      ),
      // 🟩 exrx:OlympicLifts/PowerClean "Do not jerk weight from floor; arise steadily then accelerate"
      (
        ko: '바닥에서 확 잡아채지 말고 꾸준히 일어선 뒤 가속한다',
        en: 'Don\'t jerk it off the floor — rise steadily, then accelerate',
        sourced: true,
      ),
      // 🟩 exrx:OlympicLifts/PowerClean "keeping bar close to body"
      (
        ko: '바를 몸 가까이 붙여 끌어올린다',
        en: 'Keep the bar close to your body',
        sourced: true,
      ),
      // 🟩 ace:125 "snap the elbows forward"
      (
        ko: '팔꿈치를 앞으로 돌려 바를 어깨 앞에 받는다',
        en: 'Snap the elbows forward and catch the bar on the front of your shoulders',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:OlympicLifts/PowerClean "keeping barbell close to thighs"
      (
        ko: '바가 허벅지에서 멀어진다',
        en: 'Letting the bar swing away from the thighs',
        sourced: true,
      ),
      // 🟦
      (
        ko: '기술을 익히기 전에 무게부터 올린다',
        en: 'Adding weight before learning the technique',
        sourced: false,
      ),
    ],
  ),
  // 스쿼트 (Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/BBSquat "position bar high on back of shoulders"
      (
        ko: '바는 어깨 뒤쪽 높게 얹고 어깨너비로 선다',
        en: 'Bar high on the back of your shoulders; stand shoulder width',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/BBSquat "Squat down by bending hips back while allowing knees to bend forward"
      (
        ko: '엉덩이를 뒤로 빼며 무릎을 앞으로 굽힌다',
        en: 'Sit the hips back while letting the knees bend forward',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/BBSquat "Knees should point same direction as feet throughout movement"
      (ko: '무릎은 발끝과 같은 방향으로', en: 'Knees track your toes', sourced: true),
      // 🟩 ace:11 "keep the back straight and the chest up"
      (ko: '가슴을 들고 등을 곧게', en: 'Chest up, back straight', sourced: true),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/BBSquat "Knees should point same direction as feet"
      (ko: '무릎이 안쪽으로 모인다', en: 'Knees caving inward', sourced: true),
      // 🟩 exrx:Quadriceps/BBSquat "feet flat on floor with equal distribution of weight"
      (ko: '뒤꿈치가 들린다', en: 'Heels lifting off the floor', sourced: true),
    ],
  ),
  // 프론트 스쿼트 (Front Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '프론트 스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    gear: ['barbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/BBFrontSquat "upper arms parallel to floor"
      (
        ko: '바를 어깨 앞에 얹고 위팔을 바닥과 평행하게',
        en: 'Rack the bar on the front of your shoulders, upper arms parallel to the floor',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/BBFrontSquat "Squat down by bending hips back while allowing knees to bend forward"
      (
        ko: '엉덩이를 뒤로 빼며 무릎을 앞으로 굽힌다',
        en: 'Sit the hips back while letting the knees bend forward',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/BBFrontSquat "Knees should point same direction as feet throughout movement"
      (ko: '무릎은 발끝과 같은 방향으로', en: 'Knees track your toes', sourced: true),
      // 🟩 exrx:Quadriceps/BBFrontSquat "Keep head facing forward, back straight"
      (ko: '시선은 앞, 등은 곧게', en: 'Eyes forward, back straight', sourced: true),
    ],
    mistakes: [
      // 🟦
      (
        ko: '팔꿈치가 떨어지며 상체가 앞으로 쏠린다',
        en: 'Elbows dropping so the torso tips forward',
        sourced: false,
      ),
      // 🟩 exrx:Quadriceps/BBFrontSquat "feet flat on floor"
      (ko: '뒤꿈치가 들린다', en: 'Heels lifting off the floor', sourced: true),
    ],
  ),
  // 핵스쿼트 (Hack Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '핵스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    gear: ['machine'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/SLHackSquat "Lie supine on back pad with shoulders under shoulder pad"
      (
        ko: '어깨를 패드 아래에 두고 발판에 발을 둔다',
        en: 'Shoulders under the pads, feet on the platform',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "bend hips and knees until knees are just short of complete flexion"
      (
        ko: '무릎이 완전히 굽기 직전까지 내린다',
        en: 'Lower until your knees are just short of full bend',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "pushing with both heel and forefoot"
      (
        ko: '뒤꿈치와 앞발 모두로 민다',
        en: 'Push through both heel and forefoot',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "Placing feet slightly high on platform emphasizes Gluteus Maximus"
      (
        ko: '발을 높게 두면 엉덩이, 낮게 두면 대퇴사두가 더 쓰인다',
        en: 'Feet higher works the glutes more; lower works the quads more',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/SLHackSquat "forces pelvis to pull away from back pad"
      (
        ko: '골반이 등 패드에서 떨어질 만큼 깊이 내려간다',
        en: 'Going so deep your pelvis pulls away from the back pad',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/SLHackSquat "Keep knees pointed same directions as feet"
      (
        ko: '무릎이 발끝과 다른 방향을 향한다',
        en: 'Knees pointing a different way from your feet',
        sourced: true,
      ),
    ],
  ),
  // 레그프레스 (Leg Press)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '레그프레스': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    gear: ['machine'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:154 "positioning your back and sacrum (tailbone) flat against the machine's backrest"
      (
        ko: '등과 꼬리뼈를 등받이에 붙인다',
        en: 'Keep your back and tailbone against the backrest',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/SL45LegPress "Lower sled by flexing hips and knees until knees are just short of complete flexion"
      (
        ko: '무릎이 완전히 굽기 직전까지 내린다',
        en: 'Lower until your knees are just short of full bend',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/SL45LegPress "Do not allow heels to raise off of platform"
      (
        ko: '뒤꿈치가 발판에서 뜨지 않게 민다',
        en: 'Push without letting your heels lift',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/SL45LegPress "Keep knees pointed same directions as feet"
      (
        ko: '무릎은 발끝과 같은 방향으로',
        en: 'Knees point the same way as your feet',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:154 "Do not hyperextend (lock-out) your knees"
      (
        ko: '무릎을 튕기듯 완전히 잠근다',
        en: 'Snapping the knees into lockout',
        sourced: true,
      ),
      // 🟩 ace:154 "avoid lifting your butt off the seat pad or rounding out your low back"
      (
        ko: '엉덩이가 들리거나 허리가 말린다',
        en: 'Hips lifting off the seat or the low back rounding',
        sourced: true,
      ),
    ],
  ),
  // 레그익스텐션 (Leg Extension)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: None
  '레그익스텐션': Move(
    primary: [Muscle.quads],
    gear: ['machine'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/LVLegExtension "Position knee articulation at same axis as lever fulcrum"
      (
        ko: '무릎 관절을 기계 회전축에 맞춘다',
        en: 'Line your knee joint up with the machine\'s pivot',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/LVLegExtension "Place front of lower legs under padded lever"
      (
        ko: '패드를 정강이 앞 아래쪽에 댄다',
        en: 'Pad on the front of your lower legs',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/LVLegExtension "extending knees until legs are straight"
      (
        ko: '다리가 펴질 때까지 들어 올린다',
        en: 'Raise until your legs are straight',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/LVLegExtension "prevent body rising off of seat"
      (
        ko: '손잡이를 잡아 엉덩이가 뜨지 않게',
        en: 'Hold the handles so your hips stay on the seat',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '반동으로 차올린다',
        en: 'Kicking the weight up with momentum',
        sourced: false,
      ),
      // 🟦
      (
        ko: '내릴 때 무게를 툭 떨어뜨린다',
        en: 'Dropping the weight on the way down',
        sourced: false,
      ),
    ],
  ),
  // 레그컬 (Leg Curl)
  // 근육 🟩 주동 ← ExRx Target: Hamstrings, Hamstrings
  //      🟩 보조 ← ExRx Synergists: Gastrocnemius, Sartorius, Gracilis, Popliteus, Gastrocnemius, Gracilis, Sartorius, Popliteus
  '레그컬': Move(
    primary: [Muscle.hamstrings],
    secondary: [Muscle.calves, Muscle.adductors],
    gear: ['machine'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:153 "aligning the mid-point of your knee joint with the axis of rotation"
      (
        ko: '무릎 관절을 기계 회전축에 맞춘다',
        en: 'Line your knee joint up with the machine\'s pivot',
        sourced: true,
      ),
      // 🟩 exrx:Hamstrings/LVSeatedLegCurl "Position lever pad so it makes contact with lowers leg just above ankles"
      (
        ko: '패드는 발목 바로 위에 댄다',
        en: 'The pad sits on the lower leg just above the ankle',
        sourced: true,
      ),
      // 🟩 exrx:Hamstrings/LVLyingLegCurl "Raise lever pad to back of thighs by flexing knees"
      (
        ko: '무릎을 굽혀 패드를 허벅지 뒤로 당긴다',
        en: 'Curl the pad toward the back of your thighs',
        sourced: true,
      ),
      // 🟩 ace:153 "slowly return to your starting position by lowering the resistance pads in a controlled manner"
      (ko: '천천히 되돌린다', en: 'Return slowly', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:153 "Avoid arching your back during this movement"
      (ko: '허리를 젖힌다', en: 'Arching the low back', sourced: true),
      // 🟩 exrx:Hamstrings/LVLyingLegCurl "Keep torso on bench to reduce hyperextension of lower back"
      (
        ko: '몸통이 벤치에서 뜬다(누워서 할 때)',
        en: 'Letting the torso come off the bench (lying version)',
        sourced: true,
      ),
    ],
  ),
  // 런지 (Lunge)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '런지': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    gear: ['dumbbell', 'bodyweight', 'barbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/DBLunge "Land on heel, then forefoot"
      (
        ko: '한 발을 앞으로 내딛어 뒤꿈치부터 딛는다',
        en: 'Step forward and land heel first',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/DBLunge "until knee of rear leg is almost in contact with floor"
      (
        ko: '뒷무릎이 바닥에 거의 닿을 때까지 내려간다',
        en: 'Lower until your back knee nearly touches the floor',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/DBLunge "Keep torso upright during lunge"
      (ko: '상체를 세운다', en: 'Keep your torso upright', sourced: true),
      // 🟩 exrx:Quadriceps/DBLunge "A long lunge emphasizes Gluteus Maximus; short lunge emphasizes Quadriceps"
      (
        ko: '보폭이 길면 엉덩이, 짧으면 대퇴사두가 더 쓰인다',
        en: 'A long step works the glutes more; a short step the quads',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/DBLunge "Lead knee should point same direction as foot throughout lunge"
      (ko: '앞무릎이 안쪽으로 꺾인다', en: 'Front knee caving inward', sourced: true),
      // 🟩 exrx:Quadriceps/DBLunge "Keep torso upright during lunge"
      (ko: '상체가 앞으로 무너진다', en: 'Torso collapsing forward', sourced: true),
    ],
  ),
  // 불가리안 스플릿 스쿼트 (Bulgarian Split Squat)
  // 근육 🟩 주동 ← ExRx Target: Quadriceps
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Adductor Magnus, Soleus
  '불가리안 스플릿 스쿼트': Move(
    primary: [Muscle.quads],
    secondary: [Muscle.glutes, Muscle.adductors, Muscle.calves],
    gear: ['bodyweight', 'dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "Extend leg back and place top of foot on bench"
      (
        ko: '뒷발등을 벤치에 올린다',
        en: 'Place the top of your back foot on a bench',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "Keep majority of bodyweight on forward leg, using rear leg primarily for balance"
      (
        ko: '체중은 대부분 앞다리에, 뒷다리는 균형용',
        en: 'Keep most of your weight on the front leg; the back leg is for balance',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "until knee of rear leg is almost in contact with floor"
      (
        ko: '뒷무릎이 바닥에 거의 닿을 때까지 내려간다',
        en: 'Lower until the back knee nearly touches the floor',
        sourced: true,
      ),
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "Forward knee should point same direction as foot throughout movement"
      (ko: '앞무릎은 발끝과 같은 방향으로', en: 'Front knee tracks the foot', sourced: true),
    ],
    mistakes: [
      // 🟩 exrx:Quadriceps/BWSingleLegSplitSquat "using rear leg primarily for balance"
      (ko: '뒷다리로 밀어 올라온다', en: 'Pushing up with the back leg', sourced: true),
      // 🟩 ace:366 "Keep the back straight while lowering"
      (ko: '등이 굽는다', en: 'Rounding the back', sourced: true),
    ],
  ),
  // 힙쓰러스트 (Hip Thrust)
  // 근육 🟩 주동 ← ExRx Target: Gluteus Maximus
  //      🟩 보조 ← ExRx Synergists: Quadriceps
  '힙쓰러스트': Move(
    primary: [Muscle.glutes],
    secondary: [Muscle.quads],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Position upper back on corner of bench"
      (
        ko: '등 윗부분을 벤치 모서리에 기댄다',
        en: 'Rest your upper back on the edge of the bench',
        sourced: true,
      ),
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Bar should be positioned across upper hip flexors and lower abdomen"
      (
        ko: '바는 골반 앞(아랫배 쪽)에, 필요하면 패드를 댄다',
        en: 'Place the bar across your hip crease; pad it if needed',
        sourced: true,
      ),
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Place feet on floor approximately shoulder width with knees bent"
      (
        ko: '발은 어깨너비, 무릎은 굽힌다',
        en: 'Feet about shoulder width, knees bent',
        sourced: true,
      ),
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Raise bar upward by extending hips until straight"
      (
        ko: '엉덩이가 곧게 펴질 때까지 들어 올린다',
        en: 'Drive up until your hips are straight',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:GluteusMaximus/BBHipThrust "Bench may need to be secured so it does not slide on floor"
      (
        ko: '벤치가 미끄러진다',
        en: 'Letting the bench slide on the floor',
        sourced: true,
      ),
      // 🟦
      (
        ko: '엉덩이를 과하게 올려 허리가 꺾인다',
        en: 'Pushing the hips so high the low back arches',
        sourced: false,
      ),
    ],
  ),
  // 카프레이즈 (Calf Raise)
  // 근육 🟩 주동 ← ExRx Target: Gastrocnemius
  //      🟩 보조 ← ExRx Synergists: Soleus
  '카프레이즈': Move(
    primary: [Muscle.calves],
    gear: ['machine', 'bodyweight', 'dumbbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Position toes and balls of feet on calf block with arches and heels extending off"
      (
        ko: '앞발만 발판에 올리고 뒤꿈치는 밖으로',
        en: 'Balls of your feet on the block, heels hanging off',
        sourced: true,
      ),
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Raise heels by extending ankles as high as possible"
      (
        ko: '뒤꿈치를 최대한 높이 든다',
        en: 'Raise your heels as high as possible',
        sourced: true,
      ),
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Lower heels by bending ankles until calves are stretched"
      (
        ko: '종아리가 늘어날 때까지 뒤꿈치를 내린다',
        en: 'Lower until your calves are stretched',
        sourced: true,
      ),
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Keep knees straight throughout exercise"
      (ko: '무릎은 편 상태로', en: 'Keep your knees straight', sourced: true),
    ],
    mistakes: [
      // 🟩 exrx:Gastrocnemius/LVStandingCalfRaise "Quadriceps serve as synergist muscle if knees are bent slightly during stretch"
      (
        ko: '무릎을 굽혀 허벅지 힘을 보탠다',
        en: 'Bending the knees so the thighs help',
        sourced: true,
      ),
      // 🟦
      (ko: '가동 범위를 반만 쓴다', en: 'Using only half the range', sourced: false),
    ],
  ),
  // 레그레이즈 (Leg Raise)
  // 근육 🟩 주동 ← ExRx Target: Iliopsoas
  //      🟩 보조 ← ExRx Synergists: Tensor Fasciae Latae, Pectineus, Sartorius, Adductor Longus, Adductor Brevis
  // ExRx 기준 주동근은 고관절 굴곡근이다. 복근은 허리를 말아 올릴 때만 동적으로 일한다.
  '레그레이즈': Move(
    primary: [Muscle.hipFlexors],
    secondary: [Muscle.adductors],
    gear: ['bodyweight'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Place hands under lower buttock on each side to support pelvis"
      (
        ko: '벤치에 누워 손을 엉덩이 아래 양옆에 넣어 골반을 받친다',
        en: 'Lie on a bench with your hands under your lower buttocks to support the pelvis',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Raise legs by flexing hips and knees"
      (
        ko: '엉덩이와 무릎을 굽혀 다리를 올린다',
        en: 'Raise your legs by bending hips and knees',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Return until hips and knees are extended"
      (
        ko: '엉덩이·무릎이 펴질 때까지 되돌린다',
        en: 'Return until hips and knees are straight',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "Rectus Abdominis and Obliques only contract dynamically if actual waist flexion occurs"
      (
        ko: '복근을 쓰려면 골반까지 말아 올린다',
        en: 'To work the abs, curl the pelvis up too',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:HipFlexors/BWLyingLegRaise "With no waist flexion, Rectus Abdominis and External Oblique will only act to stabilize"
      (
        ko: '다리만 오르내리며 복근 운동이라고 여긴다',
        en: 'Treating hip-only lifting as an ab exercise',
        sourced: true,
      ),
      // 🟦
      (
        ko: '내릴 때 다리를 툭 떨어뜨린다',
        en: 'Dropping the legs on the way down',
        sourced: false,
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
      Muscle.triceps,
      Muscle.sideDelts,
      Muscle.upperBack,
    ],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "Position bar in front of neck"
      (
        ko: '어깨너비보다 조금 넓게 잡고 바를 목 앞에 둔다',
        en: 'Grip slightly wider than shoulder width, bar in front of your neck',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "Press bar upward until arms are extended overhead"
      (
        ko: '팔이 펴질 때까지 머리 위로 밀어 올린다',
        en: 'Press overhead until your arms are extended',
        sourced: true,
      ),
      // 🟩 ace:71 "keeping the back straight and tall"
      (ko: '등을 곧게 세운다', en: 'Stand tall with a straight back', sourced: true),
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "Lower to front of neck"
      (
        ko: '다시 목 앞으로 내린다',
        en: 'Lower back to the front of your neck',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:71 "press the barbell directly overhead"
      (
        ko: '바를 머리 위가 아니라 앞으로 밀어낸다',
        en: 'Pressing the bar out in front instead of straight overhead',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidAnterior/BBMilitaryPress "until arms are extended overhead"
      (
        ko: '팔을 끝까지 펴지 않는다',
        en: 'Not extending the arms fully overhead',
        sourced: true,
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
      Muscle.triceps,
      Muscle.upperBack,
    ],
    gear: ['machine'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:186 "Adjust the seat height so that the handles are level with your shoulders or just higher than your shoulders"
      (
        ko: '손잡이가 어깨 높이나 조금 위에 오게 좌석을 맞춘다',
        en: 'Set the seat so the handles are at or just above shoulder height',
        sourced: true,
      ),
      // 🟩 ace:186 "slightly forward than the 3 and 9 o'clock positions"
      (
        ko: '팔꿈치를 몸 옆선보다 조금 앞에 둔다',
        en: 'Keep your elbows slightly in front of your sides',
        sourced: true,
      ),
      // 🟩 ace:186 "Continue pressing until your elbows are fully extended, but not locked"
      (
        ko: '팔꿈치를 잠그지 않고 팔을 편다',
        en: 'Press until your elbows are extended, not locked',
        sourced: true,
      ),
      // 🟩 ace:186 "Depress and retract your scapulae (pull shoulders back and down)"
      (
        ko: '어깨를 뒤·아래로 당긴 채',
        en: 'Keep your shoulders pulled back and down',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidAnterior/LVShoulderPress "Range of motion will be compromised if grip is too wide"
      (
        ko: '그립을 너무 넓게 잡아 가동 범위가 줄어든다',
        en: 'Gripping so wide that the range of motion is cut short',
        sourced: true,
      ),
      // 🟩 ace:186 "avoid arching your back throughout the exercise"
      (ko: '허리를 젖혀 민다', en: 'Arching the low back to press', sourced: true),
    ],
  ),
  // 덤벨 숄더프레스 (Dumbbell Shoulder Press)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Anterior
  //      🟩 보조 ← ExRx Synergists: Deltoid, Lateral, Supraspinatus, Triceps Brachii, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations, Pectoralis Major, Clavicular, Coracobrachialis
  '덤벨 숄더프레스': Move(
    primary: [Muscle.frontDelts],
    secondary: [
      Muscle.sideDelts,
      Muscle.triceps,
      Muscle.upperBack,
      Muscle.chest,
    ],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "Position dumbbells to each side of shoulders with elbows below wrists"
      (
        ko: '덤벨은 어깨 옆에, 팔꿈치는 손목 아래에',
        en: 'Dumbbells beside your shoulders, elbows under your wrists',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "Press dumbbells upward until arms are extended overhead"
      (
        ko: '팔이 펴질 때까지 머리 위로 민다',
        en: 'Press overhead until your arms are extended',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "Lower to sides of shoulders"
      (
        ko: '다시 어깨 옆으로 내린다',
        en: 'Lower back to the sides of your shoulders',
        sourced: true,
      ),
      // 🟦
      (
        ko: '배에 힘을 주고 발로 바닥을 누른다',
        en: 'Brace your stomach and press your feet into the floor',
        sourced: false,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidAnterior/DBShoulderPress "elbows below wrists"
      (
        ko: '팔꿈치가 손목 아래를 벗어난다',
        en: 'Letting the elbows drift out from under the wrists',
        sourced: true,
      ),
      // 🟦
      (ko: '허리를 크게 젖힌다', en: 'Arching the low back hard', sourced: false),
    ],
  ),
  // 사이드 레터럴 레이즈 (Lateral Raise)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Lateral
  //      🟩 보조 ← ExRx Synergists: Deltoid, Anterior, Supraspinatus, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations
  '사이드 레터럴 레이즈': Move(
    primary: [Muscle.sideDelts],
    secondary: [Muscle.frontDelts, Muscle.upperBack],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "maintaining slight bend through elbows"
      (
        ko: '팔꿈치를 살짝 굽힌 각도로 고정한다',
        en: 'Keep a slight, fixed bend in the elbows',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "Raise upper arms to sides until slightly bent elbows are shoulder height"
      (
        ko: '팔꿈치가 어깨 높이가 될 때까지 옆으로 든다',
        en: 'Raise to the sides until your elbows reach shoulder height',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "maintaining elbows' height above or equal to wrists"
      (
        ko: '팔꿈치를 손목과 같거나 높게',
        en: 'Keep your elbows at or above wrist height',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "To keep resistance targeted to side delt, torso is bent over slightly"
      (ko: '상체를 살짝 숙인다', en: 'Lean your torso forward slightly', sourced: true),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidLateral/DBLateralRaise "If elbows drop lower than wrists, front deltoids become primary mover instead of lateral deltoids"
      (
        ko: '팔꿈치가 손목보다 떨어져 앞어깨가 대신 든다',
        en: 'Elbows dropping below the wrists so the front delts take over',
        sourced: true,
      ),
      // 🟩 ace:26 "no arching your low back"
      (
        ko: '허리를 젖혀 반동을 쓴다',
        en: 'Arching the low back to swing the weights up',
        sourced: true,
      ),
    ],
  ),
  // 프론트 레이즈 (Front Raise)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Anterior
  //      🟩 보조 ← ExRx Synergists: Pectoralis Major, Clavicular, Deltoid, Lateral, Coracobrachialis, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations
  '프론트 레이즈': Move(
    primary: [Muscle.frontDelts],
    secondary: [Muscle.chest, Muscle.sideDelts, Muscle.upperBack],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidAnterior/DBFrontRaise "Position dumbbells in front of upper legs with elbows straight or slightly bent"
      (
        ko: '덤벨을 허벅지 앞에 두고 팔꿈치는 펴거나 살짝 굽힌다',
        en: 'Dumbbells in front of your thighs, elbows straight or slightly bent',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidAnterior/DBFrontRaise "Raise dumbbells forward and upward until upper arms are above horizontal"
      (
        ko: '위팔이 수평보다 조금 위까지 앞으로 든다',
        en: 'Raise forward until your upper arms are just above horizontal',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidAnterior/DBFrontRaise "Raise should be limited to height achieved just before tightness is felt in shoulder capsule"
      (
        ko: '어깨가 조이는 느낌 직전에서 멈춘다',
        en: 'Stop just before you feel tightness in the shoulder',
        sourced: true,
      ),
      // 🟩 ace:54 "Stiffen your torso by contracting your abdominal/core muscles"
      (ko: '배에 힘을 줘 몸통을 단단히', en: 'Brace to stiffen your torso', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:54 "no arching of your low back"
      (
        ko: '허리를 젖혀 반동을 쓴다',
        en: 'Arching the low back to swing up',
        sourced: true,
      ),
      // 🟩 ace:54 "avoid flexion and extension of your wrists"
      (ko: '손목을 꺾는다', en: 'Bending the wrists', sourced: true),
    ],
  ),
  // 벤트오버 레터럴 레이즈 (Bent Over Lateral Raise)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Posterior
  //      🟩 보조 ← ExRx Synergists: Infraspinatus, Teres Minor, Deltoid, Lateral, Trapezius, Middle, Trapezius, Lower, Rhomboids
  '벤트오버 레터럴 레이즈': Move(
    primary: [Muscle.rearDelts],
    secondary: [Muscle.upperBack, Muscle.sideDelts],
    gear: ['dumbbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "bend over through hips with back flat, close to horizontal"
      (
        ko: '무릎을 굽히고 등을 편 채 상체를 거의 수평까지 숙인다',
        en: 'Bend your knees and hinge over with a flat back, torso close to horizontal',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Position elbows with slight bend and palms facing together"
      (
        ko: '팔꿈치를 살짝 굽혀 고정하고 손바닥은 마주 보게',
        en: 'Slight fixed elbow bend, palms facing each other',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Maintain upper arms perpendicular to torso"
      (
        ko: '팔을 몸통과 직각으로, 팔꿈치가 어깨 높이까지 옆으로 든다',
        en: 'Raise to the sides, arms perpendicular to the torso, until elbows reach shoulder height',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Maintain height of elbows above wrists"
      (
        ko: '팔꿈치를 손목보다 높게',
        en: 'Keep your elbows above your wrists',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Positioning torso at 45° is not sufficient angle to target rear deltoids"
      (
        ko: '상체를 45° 정도만 숙인다 — 뒤어깨를 겨냥하기엔 부족',
        en: 'Only leaning to about 45° — not enough to target the rear delts',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/DBRearLateralRaise "Upper arm should travel in perpendicular path to torso to minimize relatively powerful latissimus dorsi involvement"
      (
        ko: '팔이 몸통 쪽으로 붙어 광배가 대신 든다',
        en: 'Arms drifting toward the torso so the lats take over',
        sourced: true,
      ),
    ],
  ),
  // 업라이트 로우 (Upright Row)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Lateral
  //      🟩 보조 ← ExRx Synergists: Deltoid, Anterior, Supraspinatus, Brachialis, Brachioradialis, Biceps Brachii, Trapezius, Middle, Trapezius, Lower, Serratus Anterior, Inferior Digitations, Infraspinatus, Teres Minor
  // ExRx 에 "Upright Row Safety" 글이 따로 있다 — 이번에 읽지 않았다.
  '업라이트 로우': Move(
    primary: [Muscle.sideDelts],
    secondary: [
      Muscle.frontDelts,
      Muscle.biceps,
      Muscle.forearms,
      Muscle.upperBack,
    ],
    gear: ['barbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:DeltoidLateral/BBUprightRow "Grasp bar with shoulder width or slightly narrower overhand grip"
      (
        ko: '어깨너비나 조금 좁게 오버그립',
        en: 'Overhand grip, shoulder width or slightly narrower',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidLateral/BBUprightRow "Pull bar to neck with elbows leading"
      (
        ko: '팔꿈치가 먼저 올라가게 바를 목 쪽으로 당긴다',
        en: 'Pull the bar toward your neck, elbows leading',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidLateral/BBUprightRow "Allow wrists to flex as bar rises"
      (
        ko: '바가 올라가며 손목이 자연스럽게 굽게 둔다',
        en: 'Let your wrists flex as the bar rises',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '어깨가 불편한데도 높이 당긴다',
        en: 'Pulling high even when the shoulder feels pinched',
        sourced: false,
      ),
      // 🟦
      (
        ko: '몸을 흔들어 반동을 쓴다',
        en: 'Swinging the body for momentum',
        sourced: false,
      ),
    ],
  ),
  // 슈러그 (Shrug)
  // 근육 🟩 주동 ← ExRx Target: Trapezius, Upper
  //      🟩 보조 ← ExRx Synergists: Trapezius, Middle, Levator Scapulae
  '슈러그': Move(
    primary: [Muscle.traps],
    secondary: [Muscle.upperBack],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:TrapeziusUpper/BBShrug "shoulder width or slightly wider"
      (
        ko: '어깨너비나 조금 넓게 바를 잡고 선다',
        en: 'Hold the bar shoulder width or slightly wider',
        sourced: true,
      ),
      // 🟩 ace:72 "raise the shoulders directly upwards to the ears"
      (
        ko: '어깨를 귀 쪽으로 곧게 들어 올린다',
        en: 'Raise your shoulders straight up toward your ears',
        sourced: true,
      ),
      // 🟩 ace:72 "lowering slowly to the original starting position"
      (ko: '천천히 내린다', en: 'Lower slowly', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:72 "DO NOT roll the shoulders"
      (ko: '어깨를 돌린다', en: 'Rolling the shoulders', sourced: true),
      // 🟦
      (
        ko: '팔꿈치를 굽혀 팔로 당긴다',
        en: 'Bending the elbows to pull with the arms',
        sourced: false,
      ),
    ],
  ),
  // 바벨컬 (Barbell Curl)
  // 근육 🟩 주동 ← ExRx Target: Biceps Brachii
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis
  '바벨컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    gear: ['barbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Biceps/BBCurl "Grasp bar with shoulder width underhand grip"
      (ko: '어깨너비 언더그립', en: 'Underhand grip, shoulder width', sourced: true),
      // 🟩 exrx:Biceps/BBCurl "With elbows to side, raise bar until forearms are vertical"
      (
        ko: '팔꿈치를 옆구리에 둔 채 팔뚝이 수직이 될 때까지 든다',
        en: 'Elbows at your sides, curl until your forearms are vertical',
        sourced: true,
      ),
      // 🟩 exrx:Biceps/BBCurl "Lower until arms are fully extended"
      (
        ko: '팔이 다 펴질 때까지 내린다',
        en: 'Lower until your arms are fully extended',
        sourced: true,
      ),
      // 🟩 ace:70 "Keep chest still, using just the arms for the movement"
      (
        ko: '가슴은 가만히, 팔만 움직인다',
        en: 'Keep your chest still — only the arms move',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:70 "Keep chest still"
      (
        ko: '상체를 흔들어 반동으로 든다',
        en: 'Swinging the torso to heave the bar',
        sourced: true,
      ),
      // 🟩 exrx:Biceps/BBCurl "Lower until arms are fully extended"
      (ko: '끝까지 내리지 않는다', en: 'Not lowering all the way', sourced: true),
    ],
  ),
  // 덤벨컬 (Dumbbell Curl)
  // 근육 🟩 주동 ← ExRx Target: Biceps Brachii
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis
  '덤벨컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    gear: ['dumbbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Biceps/DBCurl "Position two dumbbells to sides, palms facing in"
      (
        ko: '덤벨을 옆에 두고 손바닥은 안쪽',
        en: 'Dumbbells at your sides, palms facing in',
        sourced: true,
      ),
      // 🟩 exrx:Biceps/DBCurl "rotate forearm until forearm is vertical and palm faces shoulder"
      (
        ko: '팔꿈치를 옆구리에 둔 채 들며 손바닥이 어깨를 보게 돌린다',
        en: 'Elbows at your sides; curl and turn until the palm faces your shoulder',
        sourced: true,
      ),
      // 🟩 exrx:Biceps/DBCurl "Biceps may be exercised alternating (as described), simultaneous"
      (
        ko: '번갈아 해도, 동시에 해도 된다',
        en: 'Alternate or lift both together',
        sourced: true,
      ),
      // 🟩 exrx:Biceps/DBCurl "Lower to original position"
      (ko: '처음 자리까지 내린다', en: 'Lower back to the start', sourced: true),
    ],
    mistakes: [
      // 🟦
      (
        ko: '팔꿈치가 앞으로 크게 나간다',
        en: 'Elbows swinging far forward',
        sourced: false,
      ),
      // 🟦
      (
        ko: '몸을 흔들어 반동을 쓴다',
        en: 'Swinging the body for momentum',
        sourced: false,
      ),
    ],
  ),
  // 해머컬 (Hammer Curl)
  // 근육 🟩 주동 ← ExRx Target: Brachioradialis
  //      🟩 보조 ← ExRx Synergists: Brachialis, Biceps Brachii
  '해머컬': Move(
    primary: [Muscle.forearms],
    secondary: [Muscle.biceps],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:10 "palms facing your body"
      (
        ko: '손바닥이 몸을 보게 덤벨을 쥔다',
        en: 'Hold the dumbbells with palms facing your body',
        sourced: true,
      ),
      // 🟩 exrx:Brachioradialis/DBHammerCurl "raise one dumbbell until forearm is vertical and thumb faces shoulder"
      (
        ko: '엄지가 어깨를 향할 때까지 든다',
        en: 'Curl until your thumb faces your shoulder',
        sourced: true,
      ),
      // 🟩 exrx:Brachioradialis/DBHammerCurl "With elbows to sides"
      (ko: '팔꿈치는 옆구리에', en: 'Elbows stay at your sides', sourced: true),
      // 🟩 ace:10 "avoid shrugging your shoulders throughout the movement"
      (ko: '어깨를 으쓱하지 않는다', en: 'Don\'t shrug', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:10 "without moving your elbows forward"
      (ko: '팔꿈치가 앞으로 나간다', en: 'Moving the elbows forward', sourced: true),
      // 🟩 ace:10 "keeping your torso erect (no arching your low back)"
      (ko: '허리를 젖혀 든다', en: 'Arching the low back to lift', sourced: true),
    ],
  ),
  // 프리처컬 (Preacher Curl)
  // 근육 🟩 주동 ← ExRx Target: Brachialis
  //      🟩 보조 ← ExRx Synergists: Biceps Brachii, Brachioradialis
  '프리처컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    gear: ['barbell'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Brachialis/BBPreacherCurl "Seat should be adjusted to allow armpit to rest near top of pad"
      (
        ko: '겨드랑이가 패드 위쪽에 오게 좌석을 맞춘다',
        en: 'Adjust the seat so your armpits rest near the top of the pad',
        sourced: true,
      ),
      // 🟩 exrx:Brachialis/BBPreacherCurl "Back of upper arm should remain on pad throughout movement"
      (
        ko: '위팔 뒤쪽을 패드에 붙인 채',
        en: 'Keep the backs of your upper arms on the pad',
        sourced: true,
      ),
      // 🟩 exrx:Brachialis/BBPreacherCurl "Raise bar until forearms are vertical"
      (
        ko: '팔뚝이 수직이 될 때까지 든다',
        en: 'Curl until your forearms are vertical',
        sourced: true,
      ),
      // 🟩 exrx:Brachialis/BBPreacherCurl "Lower barbell until arms are fully extended"
      (
        ko: '팔이 다 펴질 때까지 내린다',
        en: 'Lower until your arms are fully extended',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Brachialis/BBPreacherCurl "Back of upper arm should remain on pad"
      (ko: '위팔이 패드에서 뜬다', en: 'Upper arms lifting off the pad', sourced: true),
      // 🟦
      (
        ko: '아래에서 무게를 툭 떨어뜨린다',
        en: 'Dropping the weight at the bottom',
        sourced: false,
      ),
    ],
  ),
  // 케이블컬 (Cable Curl)
  // 근육 🟩 주동 ← ExRx Target: Biceps Brachii
  //      🟩 보조 ← ExRx Synergists: Brachialis, Brachioradialis
  '케이블컬': Move(
    primary: [Muscle.biceps],
    secondary: [Muscle.forearms],
    gear: ['cable'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Biceps/CBCurl "Grasp low pulley cable bar with shoulder width underhand grip"
      (
        ko: '낮은 도르래 가까이 서서 어깨너비 언더그립',
        en: 'Stand close to the low pulley; underhand grip, shoulder width',
        sourced: true,
      ),
      // 🟩 exrx:Biceps/CBCurl "With elbows to side, raise bar until forearms are vertical"
      (
        ko: '팔꿈치를 옆구리에 둔 채 팔뚝이 수직이 될 때까지 든다',
        en: 'Elbows at your sides, curl until your forearms are vertical',
        sourced: true,
      ),
      // 🟩 exrx:Biceps/CBCurl "Lower until arms are fully extended"
      (
        ko: '팔이 다 펴질 때까지 내린다',
        en: 'Lower until your arms are fully extended',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (ko: '팔꿈치가 옆구리에서 떨어진다', en: 'Elbows leaving your sides', sourced: false),
      // 🟦
      (ko: '몸을 뒤로 젖혀 당긴다', en: 'Leaning back to pull', sourced: false),
    ],
  ),
  // 트라이셉스 익스텐션 (Triceps Extension)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: None
  '트라이셉스 익스텐션': Move(
    primary: [Muscle.triceps],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/DBTriExt "Position one dumbbell over head with both hands"
      (
        ko: '덤벨 하나를 두 손으로 머리 위에 든다',
        en: 'Hold one dumbbell overhead with both hands',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/DBTriExt "With elbows over head, lower forearm behind upper arm by flexing elbows"
      (
        ko: '팔꿈치는 머리 위에 두고 팔뚝만 뒤로 내린다',
        en: 'Keep the elbows overhead; lower the forearms behind',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/DBTriExt "Position wrists closer together to keep elbows from pointing out too much"
      (
        ko: '손목을 모아 팔꿈치가 너무 벌어지지 않게',
        en: 'Keep your wrists close so the elbows don\'t flare too much',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/DBTriExt "Raise dumbbell over head by extending elbows"
      (ko: '팔꿈치를 펴 들어 올린다', en: 'Extend the elbows to raise it', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:74 "without moving your upper arms"
      (ko: '위팔이 움직인다', en: 'Moving the upper arms', sourced: true),
      // 🟩 ace:74 "Be sure to avoid making contact with the back of your head"
      (ko: '덤벨이 뒷머리에 닿는다', en: 'Hitting the back of your head', sourced: true),
    ],
  ),
  // 케이블 푸시다운 (Cable Pushdown)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: None
  '케이블 푸시다운': Move(
    primary: [Muscle.triceps],
    gear: ['cable'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/CBPushdown "Position elbows to side"
      (
        ko: '높은 도르래를 보고 서서 팔꿈치를 옆구리에',
        en: 'Face the high pulley with your elbows at your sides',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/CBPushdown "Extend arms down"
      (
        ko: '팔을 끝까지 펴 내린다',
        en: 'Push down until your arms are straight',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/CBPushdown "Return until forearm is close to upper arm"
      (
        ko: '팔뚝이 위팔 가까이 올 때까지 되돌린다',
        en: 'Return until your forearm is close to your upper arm',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/CBPushdown "Stay close to cable to provide resistance at top of motion"
      (ko: '케이블 가까이 선다', en: 'Stand close to the cable', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:185 "with your elbows right next to your side"
      (
        ko: '팔꿈치가 옆구리에서 떨어진다',
        en: 'Elbows drifting away from your sides',
        sourced: true,
      ),
      // 🟩 ace:185 "keeping your torso aligned vertically with the floor"
      (
        ko: '상체를 숙여 체중으로 누른다',
        en: 'Leaning over to push with bodyweight',
        sourced: true,
      ),
    ],
  ),
  // 딥스 (Dips)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: Deltoid, Anterior, Pectoralis Major, Sternal, Pectoralis Major, Clavicular, Pectoralis Minor, Rhomboids, Levator Scapulae, Latissimus Dorsi, Coracobrachialis
  '딥스': Move(
    primary: [Muscle.triceps],
    secondary: [Muscle.frontDelts, Muscle.chest, Muscle.upperBack, Muscle.lats],
    gear: ['bodyweight'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/BWTriDip "Mount shoulder width dip bar, arms straight with shoulders above hands"
      (
        ko: '어깨너비 바에서 팔을 펴고 어깨를 손 위에',
        en: 'On shoulder-width bars, arms straight, shoulders above hands',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/BWTriDip "Keep hips straight"
      (ko: '엉덩이를 곧게 편다', en: 'Keep your hips straight', sourced: true),
      // 🟩 exrx:Triceps/BWTriDip "Lower body until slight stretch is felt in shoulders"
      (
        ko: '어깨가 살짝 늘어나는 곳까지 내려간다',
        en: 'Lower until you feel a slight stretch in the shoulders',
        sourced: true,
      ),
      // 🟩 exrx:PectoralSternal/BWChestDip "allowing elbows to flare out to sides"
      (
        ko: '가슴을 더 쓰려면 넓은 바에서 팔꿈치를 벌린다(체스트 딥)',
        en: 'For more chest, use wide bars and let the elbows flare (chest dip)',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Triceps/BWTriDip "Lower body until slight stretch is felt in shoulders"
      (
        ko: '가볍게 늘어나는 느낌을 지나 깊이 내려간다',
        en: 'Dropping deeper than a slight stretch',
        sourced: true,
      ),
      // 🟦
      (ko: '바닥에서 튕겨 올라온다', en: 'Bouncing out of the bottom', sourced: false),
    ],
  ),
  // 킥백 (Kickback)
  // 근육 🟩 주동 ← ExRx Target: Triceps Brachii
  //      🟩 보조 ← ExRx Synergists: None
  '킥백': Move(
    primary: [Muscle.triceps],
    gear: ['dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Triceps/DBKickback "Position upper arm parallel to floor"
      (
        ko: '벤치에 한 손을 짚고 위팔을 바닥과 평행하게',
        en: 'Support yourself on a bench; upper arm parallel to the floor',
        sourced: true,
      ),
      // 🟩 ace:55 "Your upper arm should remain stationary next to your torso"
      (
        ko: '위팔은 몸통 옆에 고정',
        en: 'Keep the upper arm still, next to your torso',
        sourced: true,
      ),
      // 🟩 exrx:Triceps/DBKickback "Extend arm until it is straight"
      (
        ko: '팔이 곧게 펴질 때까지 뒤로 편다',
        en: 'Extend until the arm is straight',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:55 "Avoid any arching (sagging) in your low back or any rotation in your torso"
      (
        ko: '허리가 처지거나 몸통이 돌아간다',
        en: 'Sagging low back or rotating torso',
        sourced: true,
      ),
      // 🟦
      (ko: '무게를 휘둘러 올린다', en: 'Swinging the weight up', sourced: false),
    ],
  ),
  // 플랭크 (Plank)
  // 근육 🟩 주동 ← ExRx Target: Rectus Abdominis
  //      🟩 보조 ← ExRx Synergists:
  '플랭크': Move(
    primary: [Muscle.abs],
    gear: ['bodyweight'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:RectusAbdominis/BWFrontPlank "elbows under shoulders"
      (
        ko: '팔꿈치를 어깨 바로 아래에',
        en: 'Elbows directly under your shoulders',
        sourced: true,
      ),
      // 🟩 exrx:RectusAbdominis/BWFrontPlank "Raise body upward by straightening body in straight line"
      (
        ko: '몸을 일직선으로 들어 유지한다',
        en: 'Lift your body into a straight line and hold',
        sourced: true,
      ),
      // 🟩 ace:32 "Continue to breath while holding this position"
      (ko: '숨은 계속 쉰다', en: 'Keep breathing', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:32 "Avoid any arching (sagging) in your low back, hiking (upwards) in your hips"
      (
        ko: '허리가 처지거나 엉덩이가 솟는다',
        en: 'Sagging low back or hips hiking up',
        sourced: true,
      ),
      // 🟩 ace:32 "Avoid shrugging your shoulder"
      (ko: '어깨를 으쓱한다', en: 'Shrugging the shoulders', sourced: true),
    ],
  ),
  // 사이드 플랭크 (Side Plank)
  // 근육 🟩 주동 ← ExRx Target: Obliques
  //      🟩 보조 ← ExRx Synergists:
  '사이드 플랭크': Move(
    primary: [Muscle.obliques],
    gear: ['bodyweight'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 exrx:Obliques/BWSidePlank "Place forearm on mat under shoulder perpendicular to body"
      (
        ko: '옆으로 누워 팔뚝을 어깨 아래에 몸과 직각으로',
        en: 'Lie on your side, forearm under the shoulder, perpendicular to the body',
        sourced: true,
      ),
      // 🟩 exrx:Obliques/BWSidePlank "Place upper leg directly on top of lower leg"
      (
        ko: '위 다리를 아래 다리 위에 포갠다',
        en: 'Stack your top leg on the bottom leg',
        sourced: true,
      ),
      // 🟩 exrx:Obliques/BWSidePlank "Raise body upward by straightening waist"
      (
        ko: '허리를 펴 몸을 들고 단단히 유지한다',
        en: 'Lift by straightening your waist and hold the body rigid',
        sourced: true,
      ),
      // 🟩 ace:303 "Squeeze the muscles of the stomach and glutes"
      (
        ko: '배와 엉덩이에 힘을 준다',
        en: 'Squeeze your stomach and glutes',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:303 "keep the body in a straight line from head to heels"
      (ko: '엉덩이가 처진다', en: 'Hips sagging', sourced: true),
      // 🟩 exrx:Obliques/BWSidePlank "Repeat with opposite side"
      (ko: '한쪽만 한다', en: 'Only training one side', sourced: true),
    ],
  ),
  // 크런치 (Crunch)
  // 근육 🟩 주동 ← ExRx Target: Rectus Abdominis
  //      🟩 보조 ← ExRx Synergists: Obliques
  '크런치': Move(
    primary: [Muscle.abs],
    secondary: [Muscle.obliques],
    gear: ['bodyweight'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:52 "Place your hands behind your head"
      (
        ko: '무릎을 굽히고 누워 손은 머리 뒤에',
        en: 'Lie with knees bent, hands behind your head',
        sourced: true,
      ),
      // 🟩 ace:52 "pulling your rib cage towards your pelvis"
      (
        ko: '갈비뼈를 골반 쪽으로 당기듯 상체를 만다',
        en: 'Curl up by pulling your ribs toward your pelvis',
        sourced: true,
      ),
      // 🟩 ace:52 "Continue curling up until your upper back is lifted off the mat"
      (
        ko: '허리는 바닥에 붙이고 등 윗부분만 든다',
        en: 'Keep your low back down; lift only the upper back',
        sourced: true,
      ),
      // 🟩 exrx:RectusAbdominis/BWCrunch "Certain individuals may need to keep their neck in neutral position"
      (
        ko: '사람에 따라 턱과 가슴 사이에 공간을 두고 목을 중립으로',
        en: 'Some people should keep a neutral neck with space between chin and chest',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:52 "the neck stays relaxed"
      (ko: '목에 힘을 준다', en: 'Straining the neck', sourced: true),
      // 🟩 ace:52 "Your feet, tailbone and lower back should remain in contact with the mat at all times"
      (ko: '허리가 바닥에서 뜬다', en: 'Low back leaving the mat', sourced: true),
    ],
  ),
  // 싯업 (Sit Up)
  // 근육 🟩 주동 ← ExRx Target: Rectus Abdominis
  //      🟩 보조 ← ExRx Synergists: Iliopsoas, Tensor Fasciae Latae, Rectus Femoris, Sartorius, Obliques
  '싯업': Move(
    primary: [Muscle.abs],
    secondary: [Muscle.hipFlexors, Muscle.quads, Muscle.obliques],
    gear: ['bodyweight'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:RectusAbdominis/BWSitUp "Lie supine on floor or bench with hips bent"
      (
        ko: '발을 받침에 걸고 엉덩이를 굽힌 채 눕는다',
        en: 'Hook your feet and lie with your hips bent',
        sourced: true,
      ),
      // 🟩 exrx:RectusAbdominis/BWSitUp "Raise torso from bench by bending waist and hips"
      (
        ko: '허리와 엉덩이를 굽혀 상체를 든다',
        en: 'Raise your torso by bending at the waist and hips',
        sourced: true,
      ),
      // 🟩 exrx:RectusAbdominis/BWSitUp "Return until back of shoulders contact incline board"
      (
        ko: '어깨 뒤가 바닥에 닿을 때까지 내려온다',
        en: 'Lower until the backs of your shoulders touch down',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:RectusAbdominis/BWSitUp "If upper back does not come completely down at end of movement, abdominal muscles may only be isometrically involved"
      (
        ko: '등 윗부분을 끝까지 내리지 않는다 — 복근이 버티기만 한다',
        en: 'Not lowering the upper back fully — the abs then only hold',
        sourced: true,
      ),
      // 🟦
      (
        ko: '손으로 목을 당긴다',
        en: 'Yanking the neck with your hands',
        sourced: false,
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
    gear: ['bodyweight'],
    sites: ['ExRx.net'],
    cues: [
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "Grasp and hang from high bar with slightly wider than shoulder width overhand grip"
      (
        ko: '어깨너비보다 조금 넓게 바에 매달린다',
        en: 'Hang from a high bar, grip slightly wider than shoulders',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "until hips are completely flexed or knees are well above hips"
      (
        ko: '무릎이 엉덩이보다 충분히 올라올 때까지 다리를 든다',
        en: 'Raise your legs until your knees are well above your hips',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "Return until hips and knees are extended downward"
      (
        ko: '엉덩이·무릎이 펴질 때까지 내린다',
        en: 'Lower until hips and knees are straight',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "Rectus Abdominis and Obliques only contract dynamically if actual waist flexion occurs"
      (
        ko: '복근을 쓰려면 골반까지 말아 올린다',
        en: 'To work the abs, curl the pelvis up too',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '몸을 흔들어 반동으로 든다',
        en: 'Swinging to kick the legs up',
        sourced: false,
      ),
      // 🟩 exrx:HipFlexors/BWHangingLegRaise "With no waist flexion, Rectus Abdominis and External Oblique will only act to stabilize"
      (
        ko: '다리만 올리며 복근 운동이라고 여긴다',
        en: 'Treating hip-only lifting as an ab exercise',
        sourced: true,
      ),
    ],
  ),
  // 러시안 트위스트 (Russian Twist)
  // 근육 🟩 주동 ← ExRx Target: Obliques
  //      🟩 보조 ← ExRx Synergists: Hip External Rotators, Psoas major, Quadratus lumborum, Iliocastalis lumborum, Iliocastalis thoracis
  // 근거는 ExRx·ACE 의 짐볼 러시안 트위스트와 ACE V-twist(BOSU 위) 다. 바닥에서 하는 흔한 러시안 트위스트와 같은 근육을 쓴다고 본 것은 🟦.
  '러시안 트위스트': Move(
    primary: [Muscle.obliques],
    secondary: [Muscle.hipFlexors, Muscle.lowerBack],
    gear: ['bodyweight', 'dumbbell'],
    sites: ['ACE', 'ExRx.net'],
    cues: [
      // 🟩 ace:305 "While maintaining a straight back"
      (
        ko: '상체를 뒤로 기울이고 등을 곧게',
        en: 'Lean back with a straight back',
        sourced: true,
      ),
      // 🟩 ace:305 "rotate the shoulders from side to side"
      (
        ko: '어깨를 좌우로 돌린다',
        en: 'Rotate your shoulders side to side',
        sourced: true,
      ),
      // 🟦
      (
        ko: '팔은 몸통과 직각으로 편 채 몸통째 돈다',
        en: 'Keep the arms straight and perpendicular to the torso as you turn',
        sourced: false,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '팔만 흔들고 몸통은 안 돈다',
        en: 'Swinging only the arms without turning the torso',
        sourced: false,
      ),
      // 🟦
      (ko: '등이 둥글게 말린다', en: 'Rounding the back', sourced: false),
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
        sourced: true,
      ),
      // 🟩 exrx:DeltoidLateral/CBLateralRaise "Maintain fixed slightly bent elbow position throughout exercise"
      (
        ko: '팔꿈치를 살짝 굽혀 고정한다',
        en: 'Keep a slight, fixed bend in the elbows',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidLateral/CBLateralRaise "raise arms to sides until elbows are shoulder height"
      (
        ko: '팔꿈치가 어깨 높이가 될 때까지 옆으로 든다',
        en: 'Raise to the sides until your elbows reach shoulder height',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidLateral/CBLateralRaise "Stirrup is raised by shoulder abduction, not external rotation"
      (
        ko: '팔을 바깥으로 돌려 든다',
        en: 'Rotating the arms outward to lift',
        sourced: true,
      ),
      // 🟦
      (ko: '몸을 기울여 반동을 쓴다', en: 'Leaning to swing the weight', sourced: false),
    ],
  ),
  // 리버스 펙덱 (Reverse Pec Deck)
  // 근육 🟩 주동 ← ExRx Target: Deltoid, Posterior
  //      🟩 보조 ← ExRx Synergists: Infraspinatus, Teres Minor, Deltoid, Lateral, Trapezius, Middle, Trapezius, Lower, Rhomboids
  '리버스 펙덱': Move(
    primary: [Muscle.rearDelts],
    secondary: [Muscle.upperBack, Muscle.sideDelts],
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
      'reverse fly rear delt fly',
    ),
    cues: [
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Grasp parallel handles with thumbs up at shoulder height"
      (
        ko: '가슴을 패드에 대고 손잡이를 어깨 높이에서 잡는다',
        en: 'Chest on the pad, handles at shoulder height',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Keeping elbows pointed high, pull handles apart and to rear"
      (
        ko: '팔꿈치를 높게 유지한 채 손잡이를 뒤로 벌린다',
        en: 'Keeping your elbows high, pull the handles apart and back',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "until elbows are just behind back"
      (
        ko: '팔꿈치가 등 바로 뒤에 오면 되돌린다',
        en: 'Return once your elbows are just behind your back',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Seat height and grip should be adjusted to keep arms at transverse plane of shoulders"
      (
        ko: '팔이 어깨 높이에 오게 좌석과 그립을 맞춘다',
        en: 'Set seat and grip so your arms stay at shoulder level',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidPosterior/LVRearLateralRaise "Natural tendency is for shoulders to point down which places greater emphasis on lateral deltoid"
      (
        ko: '팔꿈치가 아래로 떨어진다 — 옆어깨·광배가 대신 쓰인다',
        en: 'Elbows dropping, shifting the work to side delts and lats',
        sourced: true,
      ),
      // 🟦
      (ko: '반동으로 튕긴다', en: 'Jerking with momentum', sourced: false),
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
      'facepull',
    ),
    cues: [
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "Step back with one foot so arms and shoulders are positioned straight forward with cable taut"
      (
        ko: '높은 도르래 로프를 잡고 한 발 물러서 팔을 앞으로 편다',
        en: 'Grab the rope from a high pulley and step back so the arms are straight in front',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "keeping elbows at shoulder height"
      (
        ko: '팔꿈치를 바깥으로, 어깨 높이로',
        en: 'Point the elbows out and keep them at shoulder height',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "Keep upper arms perpendicular to trunk"
      (
        ko: '위팔을 몸통과 직각으로 유지하며 당긴다',
        en: 'Keep your upper arms perpendicular to your trunk as you pull',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "if upper arm travels closer than perpendicular to trunk"
      (
        ko: '위팔이 몸통 쪽으로 내려와 광배가 끼어든다',
        en: 'Upper arms dropping toward the torso, bringing in the lats',
        sourced: true,
      ),
      // 🟩 exrx:DeltoidPosterior/CBStandingRearDeltRowRope "if torso is positioned forward beyond vertical"
      (ko: '상체가 앞으로 숙여진다', en: 'Leaning the torso forward', sourced: true),
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
        sourced: true,
      ),
      // 🟩 exrx:TrapeziusUpper/DBShrug "Elevate shoulders as high as possible"
      (
        ko: '어깨를 최대한 높이 올린다',
        en: 'Raise your shoulders as high as possible',
        sourced: true,
      ),
      // 🟩 ace:75 "gently lower the dumbbells back towards your starting position"
      (ko: '천천히 내린다', en: 'Lower slowly', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:75 "avoiding any shoulder rotation or elbow flexion"
      (
        ko: '어깨를 돌리거나 팔꿈치를 굽힌다',
        en: 'Rolling the shoulders or bending the elbows',
        sourced: true,
      ),
      // 🟩 ace:75 "no arching in your low back"
      (ko: '허리를 젖힌다', en: 'Arching the low back', sourced: true),
    ],
  ),
  // 파머스 워크 (Farmer's Walk)
  // 근육 출처: exrx:Kettlebell/KBFarmersWalk
  // ExRx 설명: "particularly of traps and grip". 근육 목록은 없다. 안정근(허리·옆구리·엉덩이)은 ExRx 관절 동작(척추 신전·측굴, 고관절 외전 — 정적)을 옮긴 🟦.
  '파머스 워크': Move(
    primary: [Muscle.traps, Muscle.forearms],
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
      'farmers carry 파머스캐리',
    ),
    cues: [
      // 🟩 exrx:Kettlebell/KBFarmersWalk "Deadlift kettlebells from floor using legs"
      (
        ko: '다리 힘으로 바닥에서 들어 올린다',
        en: 'Lift them off the floor with your legs',
        sourced: true,
      ),
      // 🟩 ace:359 "Hold a dumbbell in each hand with a tight, firm grip"
      (
        ko: '팔은 옆으로 곧게 두고 단단히 쥔다',
        en: 'Arms straight at your sides, grip tight',
        sourced: true,
      ),
      // 🟩 ace:359 "Keep the back straight and walk"
      (
        ko: '등을 곧게 세우고 걷는다',
        en: 'Keep your back straight as you walk',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '허리를 굽혀 바닥에서 든다',
        en: 'Picking the weights up with a rounded back',
        sourced: false,
      ),
      // 🟦
      (ko: '몸이 한쪽으로 기운다', en: 'Leaning to one side', sourced: false),
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
        sourced: true,
      ),
      // 🟩 exrx:WristFlexors/BBWristCurl "underhand grip"
      (ko: '언더그립으로 잡는다', en: 'Use an underhand grip', sourced: true),
      // 🟩 exrx:WristFlexors/BBWristCurl "pointing knuckles up as high as possible"
      (ko: '손목만 굽혀 들어 올린다', en: 'Curl up using only the wrists', sourced: true),
      // 🟩 exrx:WristFlexors/BBWristCurl "Keep elbows approximately wrist height"
      (
        ko: '팔꿈치는 손목 높이 정도로',
        en: 'Keep elbows about wrist height',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:30 "extending your arms or leaning forward / backward"
      (
        ko: '몸을 앞뒤로 흔들거나 팔을 편다',
        en: 'Rocking the body or straightening the arms',
        sourced: true,
      ),
      // 🟦
      (
        ko: '무거워서 가동 범위를 반만 쓴다',
        en: 'Cutting the range short because the weight is too heavy',
        sourced: false,
      ),
    ],
  ),
  // 백 익스텐션 (Back Extension)
  // 근육 🟩 주동 ← ExRx Target: Erector Spinae, Hamstrings
  //      🟩 보조 ← ExRx Synergists: Gluteus Maximus, Hamstrings, Adductor Magnus, Erector Spinae, Gluteus Maximus, Adductor Magnus
  '백 익스텐션': Move(
    primary: [Muscle.lowerBack, Muscle.hamstrings],
    secondary: [Muscle.glutes, Muscle.adductors],
    gear: ['bodyweight'],
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
      'hyperextension 하이퍼익스텐션',
    ),
    cues: [
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Hook heels on platform lip or under padded brace"
      (
        ko: '허벅지를 패드에 대고 뒤꿈치를 받침에 건다',
        en: 'Thighs on the pad, heels hooked under the brace',
        sourced: true,
      ),
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "abdomen should not press on top side of pad when upper body is lowered"
      (
        ko: '내려갈 때 배가 패드에 눌리지 않을 높이로 맞춘다',
        en: 'Set the pad so your abdomen does not press on it as you lower',
        sourced: true,
      ),
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Raise upper body until hips and waist are extended"
      (
        ko: '엉덩이와 허리가 펴질 때까지 상체를 든다',
        en: 'Raise your upper body until hips and waist are straight',
        sourced: true,
      ),
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Begin with arms in low position and gradually position arms in higher position"
      (
        ko: '팔은 낮은 위치에서 시작해 점차 올린다',
        en: 'Start with arms low and move them higher gradually',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:ErectorSpinae/BW45HyperextensionHips "Do not lower weight beyond mild stretch throughout hamstrings and low back"
      (
        ko: '가볍게 늘어나는 느낌을 넘어 깊이 내려간다',
        en: 'Lowering past a mild stretch',
        sourced: true,
      ),
      // 🟦
      (ko: '위에서 과하게 젖힌다', en: 'Over-arching at the top', sourced: false),
    ],
  ),
  // 슈퍼맨 (Superman)
  // 근육 출처: ace:9
  // ACE 주동근: 앞·옆 삼각근, 척추기립근, 둔근, 승모근. 넷 중 허리·엉덩이를 주, 어깨·승모를 보조로 나눈 것은 🟦.
  '슈퍼맨': Move(
    primary: [Muscle.lowerBack, Muscle.glutes],
    secondary: [Muscle.frontDelts, Muscle.sideDelts, Muscle.traps],
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
        sourced: true,
      ),
      // 🟩 ace:9 "contract your abdominal and core muscles to stabilize your spine"
      (
        ko: '배에 힘을 줘 척추를 고정한다',
        en: 'Brace to stabilize your spine',
        sourced: true,
      ),
      // 🟩 ace:9 "a few inches off the floor while simultaneously raising both arms"
      (
        ko: '팔과 다리를 바닥에서 조금만 동시에 든다',
        en: 'Lift arms and legs a little off the floor at the same time',
        sourced: true,
      ),
      // 🟩 ace:9 "Hold this position briefly"
      (ko: '잠깐 멈췄다가 내린다', en: 'Hold briefly, then lower', sourced: true),
    ],
    mistakes: [
      // 🟩 ace:9 "avoiding any arching in your back or raising of your head"
      (
        ko: '허리를 과하게 꺾거나 머리를 든다',
        en: 'Over-arching the back or lifting the head',
        sourced: true,
      ),
      // 🟩 ace:9 "avoiding any rotation in each"
      (ko: '팔다리가 돌아간다', en: 'Letting the arms or legs rotate', sourced: true),
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
        sourced: true,
      ),
      // 🟩 ace:241 "Drive your right knee towards your chest"
      (
        ko: '한쪽 무릎을 가슴 쪽으로 당기며 반대 다리는 편다',
        en: 'Drive one knee toward your chest while extending the other leg',
        sourced: true,
      ),
      // 🟩 ace:241 "rotating your trunk slowly to drive your left elbow towards your right knee"
      (
        ko: '반대쪽 팔꿈치가 그 무릎으로 가게 몸통을 돌린다',
        en: 'Rotate so the opposite elbow moves toward that knee',
        sourced: true,
      ),
      // 🟩 ace:241 "This movement will press your low back into the floor"
      (
        ko: '허리는 바닥에 눌러 둔다',
        en: 'Keep your low back pressed into the mat',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '몸통은 안 돌고 팔꿈치만 빠르게 휘두른다',
        en: 'Flapping the elbows quickly instead of rotating the trunk',
        sourced: false,
      ),
      // 🟦
      (ko: '손으로 목을 당긴다', en: 'Pulling on the neck', sourced: false),
    ],
  ),
  // 버티컬 레그레이즈 (Vertical Leg Raise)
  // 근육 🟩 주동 ← ExRx Target: Iliopsoas
  //      🟩 보조 ← ExRx Synergists: Tensor Fasciae Latae, Pectineus, Sartorius, Adductor Longus, Adductor Brevis
  // ExRx 기준 주동근은 고관절 굴곡근이다. 복근은 허리를 말아 올릴 때만 동적으로 일한다.
  '버티컬 레그레이즈': Move(
    primary: [Muscle.hipFlexors],
    secondary: [Muscle.adductors],
    gear: ['bodyweight'],
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
      'captain\'s chair 캡틴스체어',
    ),
    cues: [
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "Position forearms on padded parallel bars with hands on handles, and back on vertical pad"
      (
        ko: '팔뚝을 평행 패드에 올리고 등을 수직 패드에 댄다',
        en: 'Forearms on the padded bars, back against the vertical pad',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "until hips are completely flexed or knees are well above hips"
      (
        ko: '무릎이 엉덩이보다 충분히 올라올 때까지 다리를 든다',
        en: 'Raise your legs until your knees are well above your hips',
        sourced: true,
      ),
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "Return until hips and knees are extended"
      (
        ko: '엉덩이·무릎이 펴질 때까지 내린다',
        en: 'Lower until hips and knees are straight',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:HipFlexors/BWVerticalLegRaise "With no waist flexion, Rectus Abdominis and External Oblique will only act to stabilize"
      (
        ko: '다리만 올리며 복근 운동이라고 여긴다',
        en: 'Treating hip-only lifting as an ab exercise',
        sourced: true,
      ),
      // 🟦
      (
        ko: '다리를 흔들어 반동을 쓴다',
        en: 'Swinging the legs for momentum',
        sourced: false,
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
      'adductor 어덕터',
    ),
    cues: [
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "position legs apart until slight stretch is felt"
      (
        ko: '다리를 벌린 시작 폭은 살짝 늘어나는 곳까지',
        en: 'Set the starting width to a slight stretch',
        sourced: true,
      ),
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "Lie back and grasp bars to sides"
      (
        ko: '등을 기대고 손잡이를 잡는다',
        en: 'Lean back and hold the handles',
        sourced: true,
      ),
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "Move legs together. Return and repeat"
      (
        ko: '다리를 모은 뒤 되돌린다',
        en: 'Bring your legs together, then return',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:HipAdductors/LVSeatedHipAdduction "until slight stretch is felt"
      (
        ko: '살짝 늘어나는 느낌보다 넓게 벌려 시작한다',
        en: 'Starting wider than a slight stretch',
        sourced: true,
      ),
      // 🟦
      (
        ko: '되돌릴 때 무게에 다리가 확 벌어진다',
        en: 'Letting the weight yank your legs open',
        sourced: false,
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
        sourced: true,
      ),
      // 🟩 exrx:HipAdductors/CBHipAdduction "Step out away from stack with wide stance"
      (
        ko: '넓게 서서 지지대를 잡고 먼 발로 선다',
        en: 'Stand wide, hold a support and stand on the far foot',
        sourced: true,
      ),
      // 🟩 exrx:HipAdductors/CBHipAdduction "Move near leg just in front of far leg"
      (
        ko: '가까운 다리를 반대 다리 앞까지 가져온다',
        en: 'Bring the near leg just in front of the other',
        sourced: true,
      ),
      // 🟩 ace:104 "Keep the back straight and the left knee slightly bent"
      (
        ko: '등을 곧게, 딛는 무릎은 살짝 굽힌다',
        en: 'Back straight, standing knee slightly bent',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (
        ko: '몸통을 기울여 다리를 끌어온다',
        en: 'Leaning the torso to drag the leg across',
        sourced: false,
      ),
      // 🟩 ace:104 "slowly lowering the weight"
      (
        ko: '되돌릴 때 무게에 끌려간다',
        en: 'Letting the weight snap the leg back',
        sourced: true,
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
        sourced: true,
      ),
      // 🟩 ace:39 "gently raise the lower leg off the floor while keeping the knee extended"
      (
        ko: '무릎을 편 채 아래 다리를 들어 올린다',
        en: 'Raise the bottom leg with the knee straight',
        sourced: true,
      ),
      // 🟩 ace:39 "the leg need only rise a few inches off the mat/floor"
      (
        ko: '움직임이 작다 — 조금만 들어도 된다',
        en: 'It\'s a small movement — a little lift is enough',
        sourced: true,
      ),
      // 🟩 ace:39 "The hips should remain vertical to the floor"
      (
        ko: '엉덩이는 바닥과 수직으로',
        en: 'Keep your hips stacked vertically',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 ace:39 "knee of the raised leg should not rotate upward towards the ceiling or downward towards the floor"
      (
        ko: '들어 올리는 다리의 무릎이 위나 아래로 돌아간다',
        en: 'Letting the knee of the raised leg rotate up or down',
        sourced: true,
      ),
      // 🟩 ace:39 "until your hips begin to tilt sideways"
      (
        ko: '엉덩이가 옆으로 기울 만큼 높이 든다',
        en: 'Lifting so high the hips tilt sideways',
        sourced: true,
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
    cues: [
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Place forefeet on platform with heels extending off"
      (
        ko: '앞발을 발판에, 뒤꿈치는 밖으로',
        en: 'Forefeet on the platform, heels off',
        sourced: true,
      ),
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Position lower thighs under lever pads"
      (
        ko: '허벅지 아래쪽을 패드 밑에 둔다',
        en: 'Lower thighs under the pads',
        sourced: true,
      ),
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Raise heels by extending ankles as high as possible"
      (
        ko: '뒤꿈치를 최대한 높이 든다',
        en: 'Raise your heels as high as possible',
        sourced: true,
      ),
      // 🟩 exrx:Soleus/LVSeatedCalfRaise "Lower heels by bending ankles until calves are stretched"
      (
        ko: '종아리가 늘어날 때까지 내린다',
        en: 'Lower until your calves stretch',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟦
      (ko: '가동 범위를 반만 쓴다', en: 'Half reps', sourced: false),
      // 🟦
      (ko: '반동으로 튕긴다', en: 'Bouncing', sourced: false),
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
        sourced: true,
      ),
      // 🟩 exrx:Gastrocnemius/SL45CalfRaise "Straighten knees"
      (ko: '무릎을 편다', en: 'Straighten your knees', sourced: true),
      // 🟩 exrx:Gastrocnemius/SL45CalfRaise "Raise heels by extending ankles as high as possible"
      (
        ko: '뒤꿈치를 최대한 높이 들고, 종아리가 늘어날 때까지 내린다',
        en: 'Raise your heels as high as possible, then lower until your calves stretch',
        sourced: true,
      ),
    ],
    mistakes: [
      // 🟩 exrx:Gastrocnemius/SL45CalfRaise "Quadriceps serve as synergist muscle if knees are bent slightly during stretch"
      (
        ko: '무릎을 굽혀 허벅지 힘을 보탠다',
        en: 'Bending the knees so the thighs help',
        sourced: true,
      ),
      // 🟦
      (
        ko: '발이 발판에서 미끄러진다',
        en: 'Feet slipping on the platform',
        sourced: false,
      ),
    ],
  ),
};

// 출처 열쇠 → 주소 (보관본이 있으면 함께):
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
