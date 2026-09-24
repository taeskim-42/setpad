#!/usr/bin/env python3
"""Store listings for both stores, in every language the app speaks.

**Why a script and not 80 hand-made files.** The same eight languages go to two
stores with different folder names and different length limits. Written by hand,
a language gets forgotten and the store quietly falls back to English — the app
speaks Thai but its listing does not. Here the language list is the loop.
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

# locale key -> (App Store dir, Play dir)
LOCALES = {
    'ko':      ('ko',      'ko-KR'),
    'en':      ('en-US',   'en-US'),
    'ja':      ('ja',      'ja-JP'),
    'es':      ('es-ES',   'es-ES'),
    'th':      ('th',      'th'),
    'vi':      ('vi',      'vi'),
    'zh-Hans': ('zh-Hans', 'zh-CN'),
    'zh-Hant': ('zh-Hant', 'zh-TW'),
}

T = {
'ko': dict(
  name='setpad',
  subtitle='치면 남는 운동 기록',
  short='운동도 식단도 한 줄에 치면 남는 기록. 여럿이 같이 쓰고, 기록에 물어봅니다.',
  keywords='운동기록,헬스,웨이트,근력운동,운동일지,헬스일지,식단,칼로리,벤치프레스,스쿼트,데드리프트,세트,루틴',
  promo='최대 6명이 한 기록을 같이 고치고, 기록 질문은 기간·운동을 나란히 비교합니다. 운동도 식단도 한 줄에 치면 알아서 갈라 남기고, 끼니 열량에는 출처가 붙습니다.',
  notes='이번 업데이트',
  desc='''운동 이름을 치고, 무게와 횟수를 칩니다. 그게 전부입니다.

setpad는 루틴을 미리 짜 두는 앱이 아닙니다. 세트를 끝낸 그 순간 메모장에 적듯 숫자를 칩니다. 화면을 옮겨 다니거나 드롭다운을 고를 일이 없습니다.

■ 치면 남는다
· "벤치프레스"를 치면 운동이 열리고, "80 12"를 치면 한 세트가 남습니다
· 세트 전용 키패드 — 숫자와 +/- 뿐입니다. 2.5kg씩 올리고 내립니다
· 이전 세트와 같으면 한 번만 누르면 됩니다
· 한글은 초성만 쳐도 찾습니다. 오타가 나도 찾습니다
· 오늘 한 세트가 한 화면의 표로 보이고, 칸을 눌러 바로 고칩니다

■ 운동도 식단도 한 줄에
· 같은 입력 줄에 "벤치 80kg 5x5"를 치면 운동, "점심 김밥"이나 "라면 500kcal"을 치면 식단으로 남습니다. 잘못 갈렸으면 한 번 눌러 바꿉니다
· "벤치 80kg 100개 채우기"라고 적으면 무게와 목표를 알아서 잡습니다. 설정에 못 옮긴 말은 버리지 않고 보여 줍니다
· 어제 친 루틴 줄을 다시 치면 그 설정이 그대로 붙습니다
· 인터넷이 없거나 해석이 안 되면 친 그대로 남습니다 — 기록은 막히지 않습니다

■ 기록에 묻고 비교하기
· "지난달보다 스쿼트 늘었어?", "벤치 vs 로우"처럼 물으면 저장된 세트로 계산해 표로 보여 줍니다. 기간과 운동을 나란히 비교합니다
· 숫자는 AI가 아니라 폰이 기록에서 셉니다
· 기록 질문에는 원판을 씁니다(아래 참고). 운동 이름으로 찾기는 언제나 무료입니다

■ 식단과 열량의 출처
· 식단을 글이나 사진으로 남기고, 먹은 양을 고르면 그만큼 계산합니다
· 열량 옆에 출처가 붙습니다 — 식약처 식품영양성분 DB나 USDA FoodData Central의 값이면 누르면 그 값과 원본 링크가 나오고, 표에 없으면 AI 어림이라고 적습니다
· 열량을 모르면 모른다고 적습니다. 직접 적은 kcal은 그대로 씁니다
· 그날 먹은 것과 운동으로 쓴 것을 한 줄로 봅니다

■ 같이 하기
· 코드나 링크로 최대 6명이 한 기록을 같이 씁니다. 누가 어디를 고치는지 이름표와 커서로 보입니다
· 옆 사람의 세트를 내 폰에서 대신 적고, 링크로 건넵니다
· 타바타와 박자를 여러 폰에서 같은 순간에 시작합니다. 기구 하나를 둘이 번갈아 쓰는 교대도 됩니다

■ 건강 앱 연동
· 친 운동이 건강 앱에 운동 기록으로 남습니다
· 워치가 잰 활동 칼로리를 가져옵니다 (Apple 건강, 헬스 커넥트)
· 타바타 휴식 중 워치 심박이 그 라운드 최고치보다 25bpm 내려오면 휴식을 끝내고 다음 라운드를 알립니다. 쉬는 동안 ♥ 지금 → 목표가 보입니다
· 건강 앱에서 읽은 값은 기기 밖으로 나가지 않습니다
· 운동 칼로리를 지어내지 않습니다. 잰 것이 없으면 표시하지 않습니다

■ 체육관
· 헬스장 스티커에 폰을 대면 트레이너가 짠 오늘 루틴이 열립니다. PT 예약도 앱에서 합니다
· 트레이너 모드: 체육관 직원 계정이면 아침 보고서로 오늘 수업과 확인할 일을 보고, 한 번 눌러 처리합니다

■ AI 도움과 원판
· 한 줄 설정, 식단 열량 어림, 기록 질문은 처음 쓸 때 동의를 묻습니다. 동의하면 친 문장과 식단 사진(위치 정보를 뗀 것)이 우리 서버를 거쳐 DeepSeek의 AI로 가고, 우리 서버는 그 내용을 저장하지 않습니다. 설정에서 언제든 끌 수 있고, 꺼도 기록은 그대로 됩니다
· 적기 도움(한 줄 설정·식단 어림)은 하루 10번 무료입니다
· 기록 질문은 원판을 씁니다. 처음에 몇 장을 받고, 세트 10개를 채운 날마다 1장을 받습니다
· Pro 구독: 매달 원판을 300장까지 채우고, 적기 도움은 하루 20번입니다. 무료 체험 중에는 30장까지

■ 그밖에
· kg, lb, km, 분, 초 — 하는 운동에 맞는 단위를 씁니다
· 다크 모드는 시스템 설정을 따릅니다
· 한국어, 영어, 일본어, 스페인어, 태국어, 베트남어, 중국어(간체·번체)

혼자 기록하는 데는 계정이 필요 없습니다. 체육관 연결, 같이 하기, 구독에는 로그인이 필요합니다. 광고가 없습니다. 내 기록은 기기에 저장되고, 무엇이 서버로 가는지는 개인정보 처리방침에 적었습니다.'''),

'en': dict(
  name='setpad',
  subtitle='Type a set. It is logged.',
  short='Type a set or a meal in one line. Log together, and ask your log.',
  keywords='workout,gym,lifting,strength,training log,workout log,calories,meals,bench press,squat,deadlift,sets',
  promo='Up to 6 people edit one record live. Record questions compare periods and exercises side by side. One line logs a set or a meal, and meal calories show their source.',
  notes='In this update',
  desc='''Type the exercise, type the weight and reps. That is the whole app.

setpad is not a routine builder. The moment a set is done you type the numbers, the way you would in a notes app. No screens to move between, no dropdowns to pick.

■ Typing is logging
· Type "Bench Press" and the exercise opens; type "80 12" and a set is logged
· A keypad built for sets — digits and +/-, stepping by 2.5 kg
· Same as last set? One tap
· Search tolerates typos and matches partial words
· Every set you did today sits in one table; tap a cell to fix it

■ Sets and meals in one line
· Type "bench 80kg 5x5" and it becomes an exercise; type "lunch burrito" or "ramen 500kcal" and it becomes a meal. If it guessed wrong, one tap switches it
· Write "bench 80kg, work up to 100 reps" and the weight and goal are filled in. Words it could not place are shown, never dropped
· Type yesterday's routine line again and its setup comes back
· Offline, or when it cannot be read, what you typed is kept as written — logging is never blocked

■ Ask your log, compare
· Ask "Did my squat go up since last month?" or "bench vs row" and get a table computed from your saved sets, with periods and exercises side by side
· The numbers are counted by your phone from your log, not by the AI
· Record questions use plates (see below). Searching by exercise name is always free

■ Meals, with a source for the calories
· Log meals as text or a photo, then pick how much you ate
· Calories show where they came from: a value from the Korean MFDS food composition database or USDA FoodData Central opens with the table's number and a link to the source; anything else is marked as an AI estimate
· When the calories are unknown, it says unknown. Calories you type are used as written
· See the day's intake and exercise energy in one line

■ Together
· Up to 6 people write one record together, live — name tags and cursors show who is editing what
· Log a partner's sets on your phone and hand them over with a link
· Start a Tabata or a tempo on several phones at the same moment, or take turns on one machine

■ Health app
· Your workout is written to the Health app as a workout
· Active energy measured by your watch is read back in (Apple Health, Health Connect)
· During a Tabata rest, once your watch heart rate is 25 bpm below that round's peak, the rest ends and the next round is signalled. While resting you see ♥ now → target
· What is read from your health app never leaves the device
· Exercise calories are never invented. If nothing measured them, none are shown

■ Gyms
· Hold your phone to the gym's sticker and today's routine from your trainer opens. Book PT sessions in the app
· Trainer mode: gym staff get a morning report with today's classes and to-dos, and handle each with a tap

■ AI help and plates
· One-line setup, meal calorie estimates and record questions ask for your consent the first time. With it, the text you type and meal photos (location removed) go through our server to DeepSeek's AI; our server does not store them. Turn it off any time in Settings — logging keeps working
· Input help (one-line setup, meal estimates): 10 a day, free
· Record questions use plates. You start with a few, and earn 1 on each day you log 10 sets
· Pro subscription: plates topped up to 300 each month, input help 20 a day. Up to 30 plates during a free trial

■ Also
· kg, lb, km, minutes, seconds — the unit that fits what you are doing
· Dark mode follows your system setting
· English, Korean, Japanese, Spanish, Thai, Vietnamese, Chinese (Simplified and Traditional)

Logging on your own needs no account. Gym links, working out together and subscriptions need sign-in. No ads. Your log is stored on your device; the privacy policy lists what goes to the server.'''),

'ja': dict(
  name='setpad',
  subtitle='打てば残る、筋トレ記録',
  short='運動も食事も一行で記録。みんなで一緒に書き、記録に質問できます。',
  keywords='筋トレ,ジム,ウエイト,トレーニング記録,筋トレ記録,食事記録,カロリー,ベンチプレス,スクワット,デッドリフト,セット',
  promo='最大6人で1つの記録をリアルタイムに編集。記録への質問は期間や種目を並べて比べます。運動も食事も一行で振り分けて記録し、食事のカロリーには出どころが付きます。',
  notes='今回のアップデート',
  desc='''種目名を打ち、重量と回数を打つ。それだけのアプリです。

setpadはルーティンを組み立てるアプリではありません。セットを終えたその場で、メモ帳に書くように数字を打ちます。画面を行き来したり、ドロップダウンを選んだりする必要はありません。

■ 打てば残る
・「ベンチプレス」と打てば種目が開き、「80 12」と打てば1セットが残ります
・セット専用キーパッド — 数字と+/-だけ。2.5kg刻みで上下します
・前のセットと同じなら一度押すだけです
・入力の揺れや打ち間違いがあっても検索に引っかかります
・今日の全セットが1画面の表に並び、セルをタップしてすぐ直せます

■ 運動も食事も一行で
・同じ入力欄に「ベンチ 80kg 5x5」と打てば運動、「ラーメン 500kcal」と打てば食事として残ります。振り分けが違えば一度のタップで切り替えます
・「ベンチ 80kg 100回まで」と書けば、重量と目標を自動で設定します。設定に移せなかった言葉は捨てずに表示します
・昨日打ったルーティンの行をもう一度打つと、その設定がそのまま付きます
・オフラインや解釈できないときも、入力したまま残ります — 記録は止まりません

■ 記録に質問して比べる
・「先月よりスクワットは伸びた？」「ベンチ vs ロウ」のように聞くと、保存したセットから計算して表で見せます。期間や種目を並べて比べられます
・数字は AI ではなく端末が記録から数えます
・記録への質問にはプレートを使います（下記）。種目名での検索はいつでも無料です

■ 食事とカロリーの出どころ
・食事をテキストか写真で記録し、食べた量を選ぶとその分を計算します
・カロリーの横に出どころが付きます — 韓国食品医薬品安全処の食品成分DBや USDA FoodData Central の値なら、タップでその値と元の表へのリンクが開きます。表にないものは AI の推定と表示します
・カロリーが不明なら不明と表示します。自分で入力した kcal はそのまま使います
・その日の摂取と運動消費を1行で見られます

■ 一緒に
・コードやリンクで最大6人が1つの記録を一緒に書きます。誰がどこを直しているか、名札とカーソルで見えます
・隣の人のセットを自分のスマホで代わりに記録し、リンクで渡せます
・タバタやテンポを複数のスマホで同じ瞬間にスタート。器具1台を2人で交代で使うこともできます

■ ヘルスケア連携
・記録した運動がヘルスケアにワークアウトとして残ります
・ウォッチが計測した消費エネルギーを読み込みます(Apple ヘルスケア、ヘルスコネクト)
・タバタの休憩中、ウォッチの心拍がそのラウンドの最高値より 25bpm 下がると休憩を終え、次のラウンドを知らせます。休憩中は ♥ 現在 → 目標 が表示されます
・ヘルスケアから読み取った値は端末の外に出ません
・運動のカロリーを作り出すことはありません。計測がなければ表示しません

■ ジム
・ジムのステッカーにスマホをかざすと、トレーナーが組んだ今日のルーティンが開きます。PT 予約もアプリでできます
・トレーナーモード：ジムのスタッフは朝のレポートで今日のクラスと確認事項を見て、タップ一つで処理できます

■ AI ヘルプとプレート
・一行設定、食事のカロリー推定、記録への質問は、初めて使うときに同意を確認します。同意すると、入力した文章と食事の写真（位置情報を除く）が当社サーバーを経由して DeepSeek の AI に送られ、当社サーバーには保存しません。設定でいつでもオフにでき、オフでも記録はそのまま使えます
・入力補助（一行設定・食事の推定）は1日10回まで無料です
・記録への質問はプレートを使います。最初に数枚もらえ、10セットを記録した日ごとに1枚もらえます
・Pro サブスクリプション：毎月プレートを300枚まで補充し、入力補助は1日20回。無料体験中は30枚まで

■ その他
・kg、lb、km、分、秒 — 種目に合った単位を使えます
・ダークモードはシステム設定に従います
・日本語、韓国語、英語、スペイン語、タイ語、ベトナム語、中国語（簡体字・繁体字）

一人で記録するだけならアカウントは不要です。ジム連携、一緒に、サブスクリプションにはログインが必要です。広告なし。記録は端末に保存され、サーバーに何が送られるかはプライバシーポリシーに記載しています。'''),

'es': dict(
  name='setpad',
  subtitle='Escribe la serie. Ya está.',
  short='Series y comidas en una línea. Registra en grupo y pregunta a tu registro.',
  keywords='entrenamiento,gimnasio,pesas,fuerza,calorías,comidas,press banca,sentadilla,peso muerto,series',
  promo='Hasta 6 personas editan un registro en vivo. Las preguntas comparan periodos y ejercicios. Una línea registra una serie o una comida, y las calorías muestran su fuente.',
  notes='En esta actualización',
  desc='''Escribe el ejercicio, escribe el peso y las repeticiones. Eso es toda la app.

setpad no es un creador de rutinas. En cuanto terminas una serie escribes los números, como en una app de notas. Sin pantallas ni desplegables.

■ Escribir es registrar
· Escribe "Press banca" y se abre el ejercicio; escribe "80 12" y queda la serie
· Un teclado hecho para series — dígitos y +/-, en pasos de 2,5 kg
· ¿Igual que la anterior? Un toque
· La búsqueda tolera erratas y encuentra palabras parciales
· Todas las series de hoy en una tabla: toca una celda para corregirla

■ Series y comidas en una línea
· Escribe "banca 80kg 5x5" y es un ejercicio; escribe "ramen 500kcal" y es una comida. Si se equivoca, un toque lo cambia
· Escribe "banca 80kg hasta 100 repeticiones" y el peso y el objetivo se rellenan solos. Lo que no pudo colocar se muestra, no se pierde
· Repite la línea de rutina de ayer y vuelve su configuración
· Sin conexión, o si no se puede leer, lo que escribiste queda tal cual — el registro nunca se bloquea

■ Pregunta a tu registro y compara
· Pregunta "¿Mejoró mi sentadilla desde el mes pasado?" o "banca vs remo": una tabla con tus series guardadas compara periodos y ejercicios
· Los números los cuenta tu teléfono, no la IA
· Las preguntas usan discos (ver abajo). Buscar por nombre de ejercicio es siempre gratis

■ Comidas, con la fuente de las calorías
· Registra comidas con texto o foto y elige cuánto comiste
· Las calorías muestran su fuente: un valor de la tabla del MFDS de Corea o de USDA FoodData Central muestra, al tocarlo, el número y un enlace al original; lo demás se marca como estimación de la IA
· Si no se conocen las calorías, lo dice. Las kcal que escribes se usan tal cual
· La ingesta del día y la energía del ejercicio, en una línea

■ Juntos
· Hasta 6 personas escriben un registro en vivo; nombres y cursores muestran quién edita qué
· Anota las series de tu compañero en tu teléfono y pásaselas con un enlace
· Empezad un Tabata o un tempo a la vez en varios teléfonos, o por turnos en una máquina

■ App Salud
· Tu entrenamiento se guarda en Salud
· Se lee la energía activa medida por tu reloj (Salud de Apple, Health Connect)
· En el descanso de un Tabata, cuando el pulso del reloj baja 25 lpm del máximo de la ronda, se avisa la siguiente. Mientras descansas ves ♥ ahora → objetivo
· Lo que se lee de la app de salud nunca sale del dispositivo
· Las calorías del ejercicio nunca se inventan. Si nadie las midió, no se muestran

■ Gimnasios
· Acerca el teléfono a la pegatina del gimnasio y se abre la rutina de hoy de tu entrenador. Reserva PT en la app
· Modo entrenador: el personal del gimnasio ve cada mañana las clases de hoy y lo pendiente, y lo resuelve con un toque

■ Ayuda de IA y discos
· La primera vez, la configuración en una línea, la estimación de calorías y las preguntas piden tu consentimiento. Si aceptas, tu texto y las fotos de comidas (sin ubicación) pasan por nuestro servidor a la IA de DeepSeek; nuestro servidor no los guarda. Puedes desactivarla en Ajustes; el registro sigue funcionando
· Ayuda para anotar (línea de configuración, estimación de comidas): 10 al día, gratis
· Las preguntas usan discos. Empiezas con algunos y ganas 1 cada día que registras 10 series
· Suscripción Pro: discos rellenados hasta 300 cada mes y ayuda para anotar 20 veces al día. Hasta 30 discos durante la prueba gratuita

■ Además
· kg, lb, km, minutos, segundos — la unidad de cada ejercicio
· El modo oscuro sigue la configuración del sistema
· Español, inglés, coreano, japonés, tailandés, vietnamita y chino (simplificado y tradicional)

Para registrar por tu cuenta no hace falta cuenta. Los gimnasios, entrenar juntos y las suscripciones requieren iniciar sesión. Sin anuncios. Tu registro se guarda en tu dispositivo; la política de privacidad detalla qué va al servidor.'''),

'th': dict(
  name='setpad',
  subtitle='พิมพ์เซ็ต แล้วบันทึกเลย',
  short='พิมพ์เซ็ตหรือมื้ออาหารในบรรทัดเดียว บันทึกร่วมกัน และถามบันทึกของคุณได้',
  keywords='บันทึกออกกำลังกาย,ฟิตเนส,ยกน้ำหนัก,เวทเทรนนิ่ง,แคลอรี,อาหาร,เบนช์เพรส,สควอท,เดดลิฟต์,เซ็ต,ยิม',
  promo='แก้บันทึกเดียวกันพร้อมกันได้ถึง 6 คน คำถามถึงบันทึกเทียบช่วงเวลาและท่าให้เห็นเคียงกัน พิมพ์เซ็ตหรือมื้ออาหารในบรรทัดเดียว และแคลอรีมีแหล่งที่มากำกับ',
  notes='ในการอัปเดตนี้',
  desc='''พิมพ์ชื่อท่า พิมพ์น้ำหนักและจำนวนครั้ง แค่นั้นทั้งแอป

setpad ไม่ใช่แอปสร้างโปรแกรมฝึกล่วงหน้า พอจบเซ็ตก็พิมพ์ตัวเลขลงไปทันที เหมือนจดในแอปโน้ต ไม่ต้องสลับหน้าจอ ไม่ต้องเลือกจากรายการ

■ พิมพ์คือบันทึก
· พิมพ์ "เบนช์เพรส" ท่าจะเปิดขึ้น พิมพ์ "80 12" เซ็ตก็ถูกบันทึก
· แป้นพิมพ์ที่ทำมาเพื่อเซ็ต — มีแค่ตัวเลขกับ +/- ปรับทีละ 2.5 กก.
· เหมือนเซ็ตก่อนหน้าไหม แตะครั้งเดียวพอ
· ค้นหาได้แม้พิมพ์ผิดหรือพิมพ์ไม่ครบ
· ทุกเซ็ตของวันนี้อยู่ในตารางเดียว แตะช่องเพื่อแก้ได้ทันที

■ เซ็ตและอาหารในบรรทัดเดียว
· พิมพ์ "เบนช์ 80kg 5x5" จะเป็นท่าออกกำลัง พิมพ์ "ข้าวผัด 550kcal" จะเป็นมื้ออาหาร ถ้าแยกผิดก็แตะครั้งเดียวเพื่อสลับ
· เขียนว่า "เบนช์ 80 กก. ให้ครบ 100 ครั้ง" แล้วน้ำหนักกับเป้าหมายจะถูกตั้งให้เอง คำที่ใส่ในการตั้งค่าไม่ได้จะแสดงให้เห็น ไม่ถูกทิ้ง
· พิมพ์บรรทัดโปรแกรมของเมื่อวานซ้ำ การตั้งค่าเดิมจะกลับมา
· เมื่อออฟไลน์หรืออ่านไม่ได้ สิ่งที่พิมพ์จะถูกเก็บไว้ตามนั้น — การบันทึกไม่ถูกขวาง

■ ถามบันทึกและเปรียบเทียบ
· ถามว่า "สควอทดีขึ้นกว่าเดือนที่แล้วไหม" หรือ "เบนช์ vs โรว์" แล้วจะได้ตารางที่คำนวณจากเซ็ตที่บันทึกไว้ เทียบช่วงเวลาและท่าเคียงกัน
· ตัวเลขนับโดยโทรศัพท์จากบันทึกของคุณ ไม่ใช่โดย AI
· คำถามถึงบันทึกใช้แผ่นน้ำหนัก (ดูด้านล่าง) การค้นหาด้วยชื่อท่าฟรีเสมอ

■ อาหาร พร้อมแหล่งที่มาของแคลอรี
· บันทึกมื้ออาหารด้วยข้อความหรือรูป แล้วเลือกปริมาณที่กิน
· แคลอรีบอกแหล่งที่มา: ถ้าเป็นค่าจากฐานข้อมูลส่วนประกอบอาหารของ MFDS เกาหลีหรือ USDA FoodData Central แตะแล้วจะเห็นค่าในตารางและลิงก์ต้นฉบับ ถ้าไม่ใช่จะระบุว่าเป็นค่าประมาณของ AI
· ถ้าไม่ทราบแคลอรีก็จะบอกว่าไม่ทราบ kcal ที่พิมพ์เองจะใช้ตามนั้น
· ดูการกินและพลังงานที่ใช้ออกกำลังของวันนั้นในบรรทัดเดียว

■ ออกกำลังด้วยกัน
· ใช้รหัสหรือลิงก์ให้สูงสุด 6 คนเขียนบันทึกเดียวกันพร้อมกัน ป้ายชื่อและเคอร์เซอร์บอกว่าใครกำลังแก้ตรงไหน
· จดเซ็ตของเพื่อนแทนบนโทรศัพท์ของคุณ แล้วส่งให้ด้วยลิงก์
· เริ่มทาบาตะหรือจังหวะบนหลายเครื่องในวินาทีเดียวกัน หรือสลับกันใช้เครื่องเดียวสองคน

■ แอปสุขภาพ
· การออกกำลังกายจะถูกบันทึกลงแอปสุขภาพ
· ดึงพลังงานที่นาฬิกาวัดไว้เข้ามา (Apple Health, Health Connect)
· ระหว่างพักในทาบาตะ เมื่อหัวใจที่นาฬิกาวัดได้ต่ำกว่าค่าสูงสุดของรอบนั้น 25 bpm จะจบการพักและแจ้งรอบถัดไป ระหว่างพักจะเห็น ♥ ปัจจุบัน → เป้าหมาย
· ค่าที่อ่านจากแอปสุขภาพจะไม่ออกจากอุปกรณ์
· แอปไม่แต่งแคลอรีของการออกกำลังขึ้นเอง ถ้าไม่มีการวัดก็จะไม่แสดง

■ ยิม
· แตะโทรศัพท์ที่สติกเกอร์ของยิม โปรแกรมวันนี้ที่เทรนเนอร์จัดไว้จะเปิดขึ้น จอง PT ได้ในแอป
· โหมดเทรนเนอร์: พนักงานยิมจะได้รายงานตอนเช้าเรื่องคลาสวันนี้และสิ่งที่ต้องตรวจ แล้วจัดการได้ในแตะเดียว

■ ตัวช่วย AI และแผ่นน้ำหนัก
· การตั้งค่าบรรทัดเดียว การประมาณแคลอรีอาหาร และคำถามถึงบันทึก จะขอความยินยอมเมื่อใช้ครั้งแรก เมื่อยินยอม ข้อความที่พิมพ์และรูปอาหาร (ลบตำแหน่งแล้ว) จะส่งผ่านเซิร์ฟเวอร์ของเราไปยัง AI ของ DeepSeek โดยเซิร์ฟเวอร์ของเราไม่จัดเก็บไว้ ปิดได้ทุกเมื่อในการตั้งค่า และการบันทึกยังใช้ได้ตามปกติ
· ตัวช่วยจด (ตั้งค่าบรรทัดเดียว ประมาณอาหาร) ฟรีวันละ 10 ครั้ง
· คำถามถึงบันทึกใช้แผ่นน้ำหนัก เริ่มต้นได้รับจำนวนหนึ่ง และได้ 1 แผ่นทุกวันที่บันทึกครบ 10 เซ็ต
· สมัครสมาชิก Pro: เติมแผ่นน้ำหนักให้ถึง 300 แผ่นทุกเดือน ตัวช่วยจดวันละ 20 ครั้ง ระหว่างทดลองใช้ฟรีได้ถึง 30 แผ่น

■ อื่น ๆ
· กก., ปอนด์, กม., นาที, วินาที — เลือกหน่วยให้ตรงกับสิ่งที่ทำ
· โหมดมืดตามการตั้งค่าของระบบ
· ไทย อังกฤษ เกาหลี ญี่ปุ่น สเปน เวียดนาม และจีน (ตัวย่อและตัวเต็ม)

การบันทึกคนเดียวไม่ต้องมีบัญชี การเชื่อมยิม การออกกำลังด้วยกัน และการสมัครสมาชิกต้องเข้าสู่ระบบ ไม่มีโฆษณา บันทึกของคุณเก็บไว้ในเครื่อง และนโยบายความเป็นส่วนตัวระบุว่าอะไรถูกส่งไปเซิร์ฟเวอร์'''),

'vi': dict(
  name='setpad',
  subtitle='Gõ một hiệp là xong',
  short='Gõ hiệp tập hay bữa ăn trên một dòng. Ghi cùng nhau và hỏi nhật ký của bạn.',
  keywords='nhật ký tập,gym,tạ,thể hình,sức mạnh,calo,bữa ăn,đẩy ngực,squat,deadlift,hiệp,fitness',
  promo='Tối đa 6 người cùng sửa một nhật ký theo thời gian thực. Câu hỏi so sánh giai đoạn và bài tập cạnh nhau. Một dòng ghi hiệp tập hay bữa ăn, và calo luôn có nguồn.',
  notes='Trong bản cập nhật này',
  desc='''Gõ tên bài tập, gõ mức tạ và số lần. Cả ứng dụng chỉ có vậy.

setpad không phải công cụ dựng giáo án. Xong hiệp nào bạn gõ số ngay lúc đó, như viết vào ứng dụng ghi chú. Không phải chuyển qua lại giữa các màn hình, không phải chọn từ danh sách xổ xuống.

■ Gõ là ghi
· Gõ "Đẩy ngực" là bài tập mở ra; gõ "80 12" là một hiệp được ghi
· Bàn phím làm riêng cho hiệp — chỉ có số và +/-, bước 2,5 kg
· Giống hiệp trước? Chạm một lần
· Tìm kiếm vẫn ra kết quả dù gõ sai hoặc gõ thiếu
· Mọi hiệp hôm nay nằm trong một bảng; chạm vào ô để sửa ngay

■ Hiệp tập và bữa ăn trên một dòng
· Gõ "đẩy ngực 80kg 5x5" là bài tập; gõ "phở 450kcal" là bữa ăn. Nếu đoán sai, chạm một lần để đổi
· Viết "đẩy ngực 80kg cho đủ 100 lần" là mức tạ và mục tiêu tự được điền. Những chữ không đưa được vào thiết lập vẫn hiện ra, không bị bỏ
· Gõ lại dòng giáo án hôm qua là thiết lập cũ quay lại
· Khi ngoại tuyến hoặc không đọc được, điều bạn gõ được giữ nguyên — việc ghi không bao giờ bị chặn

■ Hỏi nhật ký và so sánh
· Hỏi "Squat có tăng so với tháng trước không?" hay "đẩy ngực vs chèo tạ" để nhận bảng tính từ các hiệp đã lưu, so giai đoạn và bài tập cạnh nhau
· Các con số do điện thoại đếm từ nhật ký của bạn, không phải AI
· Câu hỏi về nhật ký dùng bánh tạ (xem bên dưới). Tìm theo tên bài tập luôn miễn phí

■ Bữa ăn, có nguồn của calo
· Ghi bữa ăn bằng chữ hoặc ảnh, rồi chọn lượng đã ăn
· Calo cho biết nguồn: nếu giá trị lấy từ cơ sở dữ liệu thành phần thực phẩm của MFDS Hàn Quốc hoặc USDA FoodData Central, chạm vào sẽ thấy số trong bảng và liên kết tới nguồn; nếu không sẽ ghi là AI ước tính
· Khi chưa rõ calo, ứng dụng ghi là chưa rõ. Số kcal bạn gõ được dùng đúng như vậy
· Xem lượng nạp và năng lượng tập trong ngày trên một dòng

■ Cùng nhau
· Tối đa 6 người cùng viết một nhật ký theo thời gian thực; thẻ tên và con trỏ cho thấy ai đang sửa chỗ nào
· Ghi hộ các hiệp của bạn tập trên điện thoại của bạn rồi gửi bằng liên kết
· Bắt đầu Tabata hoặc nhịp trên nhiều máy cùng một lúc, hoặc hai người luân phiên trên một máy tập

■ Ứng dụng Sức khoẻ
· Buổi tập được ghi vào Sức khoẻ như một buổi tập
· Năng lượng hoạt động do đồng hồ đo được đọc về (Apple Health, Health Connect)
· Khi nghỉ Tabata, nhịp tim từ đồng hồ giảm 25 bpm so với mức cao nhất của hiệp đó thì thời gian nghỉ kết thúc và hiệp tiếp theo được báo. Khi nghỉ bạn thấy ♥ hiện tại → mục tiêu
· Dữ liệu đọc từ ứng dụng sức khỏe không rời khỏi thiết bị
· Ứng dụng không tự bịa ra calo của buổi tập. Không đo được thì không hiển thị

■ Phòng tập
· Chạm điện thoại vào nhãn dán của phòng tập là giáo án hôm nay do huấn luyện viên soạn mở ra. Đặt lịch PT ngay trong ứng dụng
· Chế độ huấn luyện viên: nhân viên phòng tập nhận báo cáo buổi sáng về lớp hôm nay và việc cần xem, xử lý chỉ với một chạm

■ Trợ giúp AI và bánh tạ
· Thiết lập một dòng, ước tính calo bữa ăn và câu hỏi về nhật ký sẽ hỏi sự đồng ý của bạn ở lần đầu. Khi đồng ý, chữ bạn gõ và ảnh bữa ăn (đã bỏ vị trí) đi qua máy chủ của chúng tôi tới AI của DeepSeek; máy chủ của chúng tôi không lưu lại. Tắt bất cứ lúc nào trong Cài đặt — việc ghi vẫn hoạt động
· Trợ giúp ghi (thiết lập một dòng, ước tính bữa ăn): miễn phí 10 lần mỗi ngày
· Câu hỏi về nhật ký dùng bánh tạ. Bạn có sẵn vài bánh lúc đầu và nhận 1 bánh mỗi ngày ghi đủ 10 hiệp
· Gói Pro: bánh tạ được nạp lên tới 300 mỗi tháng, trợ giúp ghi 20 lần mỗi ngày. Tối đa 30 bánh trong thời gian dùng thử miễn phí

■ Ngoài ra
· kg, lb, km, phút, giây — đơn vị hợp với việc bạn đang làm
· Chế độ tối theo cài đặt hệ thống
· Tiếng Việt, Anh, Hàn, Nhật, Tây Ban Nha, Thái và Trung (giản thể, phồn thể)

Tự ghi một mình thì không cần tài khoản. Liên kết phòng tập, tập cùng nhau và gói đăng ký cần đăng nhập. Không quảng cáo. Nhật ký được lưu trên máy của bạn; chính sách quyền riêng tư ghi rõ những gì được gửi lên máy chủ.'''),

'zh-Hans': dict(
  name='setpad',
  subtitle='打一下，这组就记下了',
  short='一行输入训练或饮食，和朋友一起记录，还能向记录提问。',
  keywords='健身记录,举铁,力量训练,训练日志,饮食记录,热量,卧推,深蹲,硬拉,组数,健身房',
  promo='最多 6 人实时共同编辑一份记录；记录提问会把时间段和动作并排比较；一行输入训练或饮食自动分辨，餐食热量标明出处。',
  notes='本次更新',
  desc='''输入动作名，输入重量和次数。整个应用就这些。

setpad 不是用来提前编排计划的。做完一组，当场把数字打上去，就像在备忘录里写字一样。不用在页面之间来回切换，也不用从下拉框里挑。

■ 打字即记录
· 输入“卧推”，动作就打开；输入“80 12”，一组就记下了
· 专为记录组数做的键盘 — 只有数字和 +/-，每次 2.5 公斤
· 和上一组一样？点一下就行
· 打错字、只打一半也能搜到
· 今天做的所有组都在一张表里，点格子即可修改

■ 训练和饮食，一行搞定
· 在同一输入行输入“卧推 80kg 5x5”就是训练，输入“拉面 500kcal”就是饮食。分错了点一下就能切换
· 写“卧推 80kg 做满 100 次”，重量和目标会自动填好。放不进设置的字会显示出来，不会丢掉
· 再次输入昨天的训练行，原来的设置会自动带上
· 离线或无法解析时，你输入的内容会原样保留 — 记录不会被挡住

■ 向记录提问、比较
· 问“深蹲比上个月涨了吗？”或“卧推 vs 划船”，就会用保存的组数算出表格，把时间段和动作并排比较
· 数字由手机根据你的记录计算，而不是 AI
· 记录提问会用到杠铃片（见下文）。按动作名称查找始终免费

■ 饮食与热量出处
· 用文字或照片记录饮食，选择吃了多少就按量计算
· 热量旁标明出处：若数值来自韩国食药处食品营养成分数据库或 USDA FoodData Central，点一下即可看到表中的数值和原始链接；否则标为 AI 估算
· 不知道热量时就标为未知。自己填写的 kcal 原样使用
· 用一行查看当天的摄入和运动消耗

■ 一起练
· 用代码或链接，最多 6 人实时共写一份记录；名牌和光标显示谁在改哪里
· 在自己的手机上替同伴记录组数，再用链接交给对方
· 多台手机在同一瞬间开始 Tabata 或节拍，也可以两人轮流使用一台器械

■ 健康 App
· 训练会作为一次锻炼写入“健康”App
· 读取手表测得的活动能量(Apple 健康、Health Connect)
· Tabata 休息期间,手表心率比该轮最高值低 25 bpm 时,休息结束并提示下一轮。休息时显示 ♥ 当前 → 目标
· 从健康应用读取的数据不会离开设备
· 不会编造运动消耗的卡路里。没有测量时不显示

■ 健身房
· 把手机靠近健身房的贴纸，教练安排的今日训练计划就会打开。也能在 App 里预约私教
· 教练模式：健身房员工每天早上收到报告，查看今天的课程和待办事项，点一下即可处理

■ AI 帮助与杠铃片
· 一行设置、餐食热量估算和记录提问在第一次使用时会征求你的同意。同意后，你输入的文字和餐食照片（已去除位置）会经我们的服务器发送给 DeepSeek 的 AI，我们的服务器不保存这些内容。可随时在设置中关闭，关闭后记录照常可用
· 输入帮助（一行设置、餐食估算）每天免费 10 次
· 记录提问使用杠铃片。一开始会有几片，每天完成 10 组再送 1 片
· Pro 订阅：每月把杠铃片补足到 300 片，输入帮助每天 20 次。免费试用期间最多 30 片

■ 其他
· 公斤、磅、公里、分钟、秒 — 用适合当前动作的单位
· 深色模式跟随系统设置
· 简体中文、繁体中文、英语、韩语、日语、西班牙语、泰语、越南语

独自记录不需要账号。连接健身房、一起练和订阅需要登录。没有广告。你的记录保存在设备上，哪些内容会发送到服务器，请见隐私政策。'''),

'zh-Hant': dict(
  name='setpad',
  subtitle='打一下，這組就記下了',
  short='一行輸入訓練或飲食，和朋友一起記錄，還能向紀錄提問。',
  keywords='健身紀錄,重訓,肌力訓練,訓練日誌,飲食紀錄,熱量,臥推,深蹲,硬舉,組數,健身房',
  promo='最多 6 人即時共同編輯一份紀錄；紀錄提問會把時段和動作並排比較；一行輸入訓練或飲食自動分辨，餐點熱量標明出處。',
  notes='本次更新',
  desc='''輸入動作名稱，輸入重量和次數。整個 App 就這些。

setpad 不是用來事先編排課表的。做完一組，當場把數字打上去，就像在備忘錄裡寫字一樣。不必在頁面之間來回切換，也不必從下拉選單裡挑。

■ 打字即紀錄
· 輸入「臥推」，動作就打開；輸入「80 12」，一組就記下了
· 專為紀錄組數做的鍵盤 — 只有數字和 +/-，每次 2.5 公斤
· 和上一組一樣？點一下就好
· 打錯字、只打一半也搜得到
· 今天做的所有組都在一張表裡，點格子即可修改

■ 訓練和飲食，一行搞定
· 在同一輸入列輸入「臥推 80kg 5x5」就是訓練，輸入「拉麵 500kcal」就是飲食。分錯了點一下就能切換
· 寫「臥推 80kg 做滿 100 下」，重量和目標會自動填好。放不進設定的字會顯示出來，不會丟掉
· 再次輸入昨天的課表列，原本的設定會自動帶上
· 離線或無法解析時，你輸入的內容會原樣保留 — 紀錄不會被擋住

■ 向紀錄提問、比較
· 問「深蹲比上個月進步了嗎？」或「臥推 vs 划船」，就會用儲存的組數算出表格，把時段和動作並排比較
· 數字由手機根據你的紀錄計算，而不是 AI
· 紀錄提問會用到槓片（見下文）。依動作名稱搜尋始終免費

■ 飲食與熱量出處
· 用文字或照片記錄飲食，選擇吃了多少就依量計算
· 熱量旁標明出處：若數值來自韓國食藥處食品營養成分資料庫或 USDA FoodData Central，點一下即可看到表中的數值和原始連結；否則標為 AI 估算
· 不知道熱量時就標為未知。自己填寫的 kcal 原樣使用
· 用一行查看當天的攝取和運動消耗

■ 一起練
· 用代碼或連結，最多 6 人即時共寫一份紀錄；名牌和游標顯示誰在改哪裡
· 在自己的手機上替夥伴記錄組數，再用連結交給對方
· 多支手機在同一瞬間開始 Tabata 或節拍，也可以兩人輪流使用一台器材

■ 健康 App
· 訓練會以一次體能訓練寫入「健康」App
· 讀取手錶測得的活動能量(Apple 健康、Health Connect)
· Tabata 休息期間,手錶心率比該輪最高值低 25 bpm 時,休息結束並提示下一輪。休息時顯示 ♥ 目前 → 目標
· 從健康 App 讀取的資料不會離開裝置
· 不會編造運動消耗的卡路里。沒有測量時不顯示

■ 健身房
· 把手機靠近健身房的貼紙，教練安排的今日課表就會打開。也能在 App 裡預約教練課
· 教練模式：健身房員工每天早上收到報告，查看今天的課程和待辦事項，點一下即可處理

■ AI 協助與槓片
· 一行設定、餐點熱量估算和紀錄提問在第一次使用時會徵求你的同意。同意後，你輸入的文字和餐點照片（已移除位置）會經我們的伺服器傳送給 DeepSeek 的 AI，我們的伺服器不會儲存這些內容。可隨時在設定中關閉，關閉後紀錄照常可用
· 輸入幫助（一行設定、餐點估算）每天免費 10 次
· 紀錄提問使用槓片。一開始會有幾片，每天完成 10 組再送 1 片
· Pro 訂閱：每月把槓片補足到 300 片，輸入幫助每天 20 次。免費試用期間最多 30 片

■ 其他
· 公斤、磅、公里、分鐘、秒 — 用適合當前動作的單位
· 深色模式跟隨系統設定
· 繁體中文、簡體中文、英文、韓文、日文、西班牙文、泰文、越南文

獨自記錄不需要帳號。連結健身房、一起練和訂閱需要登入。沒有廣告。你的紀錄儲存在裝置上，哪些內容會傳送到伺服器，請見隱私權政策。'''),
}

PRIVACY = 'https://darak.studio/setpad-privacy'

# 자동 갱신 구독을 파는 앱은 App Store 설명에 이용약관(EULA) 링크가 있어야 한다.
# 없으면 심사가 시작도 안 된다(2026-09-21 반려: "does not include a functional
# link to the Terms of Use (EULA) in the app metadata"). 따로 만든 약관이 없으므로
# Apple 표준 EULA 를 건다. **iOS 설명에만 붙인다** — Play 와는 상관없는 문서다.
EULA = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
LEGAL = {
    'ko':      ('이용약관(EULA)', '개인정보 처리방침'),
    'en':      ('Terms of Use (EULA)', 'Privacy Policy'),
    'ja':      ('利用規約 (EULA)', 'プライバシーポリシー'),
    'es':      ('Términos de uso (EULA)', 'Política de privacidad'),
    'th':      ('ข้อกำหนดการใช้งาน (EULA)', 'นโยบายความเป็นส่วนตัว'),
    'vi':      ('Điều khoản sử dụng (EULA)', 'Chính sách quyền riêng tư'),
    'zh-Hans': ('使用条款 (EULA)', '隐私政策'),
    'zh-Hant': ('使用條款 (EULA)', '隱私權政策'),
}


# 이번 버전(1.4.0)에 더해진 것. 머리말(notes) 아래에 이 순서로 붙는다. Play 의 변경
# 사항은 500자 한도라 앞에서부터 들어가는 만큼만 싣는다 — 중요한 것을 앞에 둔다.
NEWS = {
    'ko': ['같이 하기: 최대 6명이 한 기록을 실시간으로 같이 고칩니다 — 이름표와 커서로 누가 어디를 고치는지 보입니다',
           '한 입력 줄에 운동도 식단도 — 치면 알아서 가르고, 잘못 갈렸으면 한 번 눌러 바꿉니다',
           '기록 질문이 기간과 운동을 나란히 비교해 표로 보여 줍니다',
           '끼니 열량에 출처가 붙습니다 — 식약처·USDA 표의 값과 원본 링크',
           '원판과 Pro 구독: 기록 질문은 원판을 쓰고, 세트 10개를 채운 날마다 1장을 받습니다',
           'AI 도움은 처음 쓸 때 DeepSeek로 무엇을 보내는지 알리고 동의를 묻습니다. 설정에서 언제든 끌 수 있습니다',
           '옆 사람의 세트를 내 폰에서 대신 적고 링크로 건넵니다',
           '트레이너 모드: 체육관 직원은 아침 보고서로 오늘 수업과 확인할 일을 보고 한 번에 처리합니다',
           '친 글은 버리지 않습니다 — 설정에 못 옮긴 말은 보이고, 해석이 안 돼도 친 그대로 남습니다'],
    'en': ['Together: up to 6 people edit one record live — name tags and cursors show who is editing what',
           'Sets and meals in one input line — it sorts them as you type, and one tap switches a wrong guess',
           'Record questions compare periods and exercises side by side in a table',
           'Meal calories show their source — the MFDS or USDA table value with a link to the original',
           'Plates and Pro: record questions use plates, and you earn 1 on each day you log 10 sets',
           'AI help tells you what goes to DeepSeek and asks for consent the first time. Turn it off any time in Settings',
           'Log a partner\'s sets on your phone and hand them over with a link',
           'Trainer mode: gym staff get a morning report with today\'s classes and to-dos, handled in a tap',
           'Nothing you type is thrown away — words that could not be placed are shown, and unreadable lines are kept as typed'],
    'ja': ['一緒に：最大6人で1つの記録をリアルタイムに編集 — 名札とカーソルで誰がどこを直しているか見えます',
           '1つの入力欄で運動も食事も — 自動で振り分け、違っていれば一度のタップで切り替え',
           '記録への質問が期間や種目を並べて表で比べます',
           '食事のカロリーに出どころ — 食品医薬品安全処・USDA の表の値と元のリンク',
           'プレートと Pro：記録への質問はプレートを使い、10セットを記録した日ごとに1枚もらえます',
           'AI ヘルプは初回に DeepSeek へ何を送るかを示して同意を確認。設定でいつでもオフにできます',
           '隣の人のセットを自分のスマホで代わりに記録し、リンクで渡せます',
           'トレーナーモード：ジムのスタッフは朝のレポートで今日のクラスと確認事項を見てタップで処理',
           '入力は捨てません — 設定に移せなかった言葉は表示され、解釈できなくても入力のまま残ります'],
    'es': ['Juntos: hasta 6 personas editan un registro en vivo; etiquetas y cursores muestran quién edita qué',
           'Series y comidas en una sola línea: las separa al escribir y un toque corrige un error',
           'Las preguntas comparan periodos y ejercicios lado a lado en una tabla',
           'Las calorías muestran su fuente: el valor de la tabla del MFDS o del USDA con enlace al original',
           'Discos y Pro: las preguntas usan discos y ganas 1 cada día que registras 10 series',
           'La ayuda de IA explica qué va a DeepSeek y pide tu consentimiento la primera vez. Desactívala cuando quieras en Ajustes',
           'Anota las series de tu compañero en tu teléfono y pásaselas con un enlace',
           'Modo entrenador: el personal del gimnasio recibe un informe matutino con las clases y pendientes de hoy',
           'Nada de lo que escribes se pierde: lo que no se pudo colocar se muestra y lo ilegible queda tal cual'],
    'th': ['ออกกำลังด้วยกัน: สูงสุด 6 คนแก้บันทึกเดียวกันพร้อมกัน ป้ายชื่อและเคอร์เซอร์บอกว่าใครแก้ตรงไหน',
           'เซ็ตและอาหารในช่องพิมพ์เดียว แยกให้เองขณะพิมพ์ ถ้าแยกผิดแตะครั้งเดียวเพื่อสลับ',
           'คำถามถึงบันทึกเทียบช่วงเวลาและท่าเคียงกันในตาราง',
           'แคลอรีของอาหารบอกแหล่งที่มา — ค่าจากตาราง MFDS หรือ USDA พร้อมลิงก์ต้นฉบับ',
           'แผ่นน้ำหนักและ Pro: คำถามถึงบันทึกใช้แผ่นน้ำหนัก และได้ 1 แผ่นทุกวันที่บันทึกครบ 10 เซ็ต',
           'ตัวช่วย AI บอกว่าอะไรจะส่งไปยัง DeepSeek และขอความยินยอมในครั้งแรก ปิดได้ทุกเมื่อในการตั้งค่า',
           'จดเซ็ตของเพื่อนแทนบนโทรศัพท์ของคุณ แล้วส่งให้ด้วยลิงก์',
           'โหมดเทรนเนอร์: พนักงานยิมได้รายงานตอนเช้าเรื่องคลาสวันนี้และสิ่งที่ต้องตรวจ จัดการได้ในแตะเดียว',
           'ไม่ทิ้งสิ่งที่พิมพ์ — คำที่ใส่ในการตั้งค่าไม่ได้จะแสดงให้เห็น และบรรทัดที่อ่านไม่ได้ก็เก็บไว้ตามที่พิมพ์'],
    'vi': ['Cùng nhau: tối đa 6 người cùng sửa một nhật ký theo thời gian thực — thẻ tên và con trỏ cho thấy ai sửa chỗ nào',
           'Hiệp tập và bữa ăn trên cùng một dòng nhập — tự phân loại khi gõ, đoán sai thì chạm một lần để đổi',
           'Câu hỏi về nhật ký so sánh giai đoạn và bài tập cạnh nhau trong bảng',
           'Calo bữa ăn có nguồn — giá trị từ bảng MFDS hoặc USDA kèm liên kết gốc',
           'Bánh tạ và Pro: câu hỏi dùng bánh tạ, và bạn nhận 1 bánh mỗi ngày ghi đủ 10 hiệp',
           'Trợ giúp AI cho biết những gì gửi tới DeepSeek và hỏi sự đồng ý ở lần đầu. Tắt bất cứ lúc nào trong Cài đặt',
           'Ghi hộ các hiệp của bạn tập trên điện thoại của bạn rồi gửi bằng liên kết',
           'Chế độ huấn luyện viên: nhân viên phòng tập nhận báo cáo buổi sáng về lớp hôm nay và việc cần xem',
           'Không bỏ điều bạn gõ — chữ không đưa được vào thiết lập vẫn hiện ra, dòng không đọc được giữ nguyên'],
    'zh-Hans': ['一起练：最多 6 人实时共同编辑一份记录，名牌和光标显示谁在改哪里',
                '训练和饮食用同一输入行 — 输入时自动分辨，分错了点一下切换',
                '记录提问把时间段和动作并排放进表格比较',
                '餐食热量标明出处 — 食药处或 USDA 表中的数值和原始链接',
                '杠铃片与 Pro：记录提问使用杠铃片，每天完成 10 组送 1 片',
                'AI 帮助首次使用时说明会发送什么给 DeepSeek 并征求同意，可随时在设置中关闭',
                '在自己的手机上替同伴记录组数，再用链接交给对方',
                '教练模式：健身房员工每天早上收到报告，查看今天的课程和待办并一键处理',
                '输入的内容不会丢 — 放不进设置的字会显示出来，无法解析时也照原样保留'],
    'zh-Hant': ['一起練：最多 6 人即時共同編輯一份紀錄，名牌和游標顯示誰在改哪裡',
                '訓練和飲食用同一輸入列 — 輸入時自動分辨，分錯了點一下切換',
                '紀錄提問把時段和動作並排放進表格比較',
                '餐點熱量標明出處 — 食藥處或 USDA 表中的數值和原始連結',
                '槓片與 Pro：紀錄提問使用槓片，每天完成 10 組送 1 片',
                'AI 協助首次使用時說明會傳送什麼給 DeepSeek 並徵求同意，可隨時在設定中關閉',
                '在自己的手機上替夥伴記錄組數，再用連結交給對方',
                '教練模式：健身房員工每天早上收到報告，查看今天的課程和待辦並一鍵處理',
                '輸入的內容不會丟 — 放不進設定的字會顯示出來，無法解析時也照原樣保留'],
}


def release_notes(key: str) -> str:
    return '\n'.join([T[key]['notes'], ''] + [f'· {n}' for n in NEWS[key]])


# Play 의 '새로운 기능'은 언어마다 500자까지다. 넘으면 올리기가 통째로 거절된다.
PLAY_CHANGELOG_CAP = 500


def play_changelog(key: str) -> str:
    """머리말과, 한도 안에 들어가는 만큼의 NEWS — 앞의 것이 먼저다."""
    text = T[key]['notes']
    for n in NEWS[key]:
        more = f'{text}\n· {n}'
        if len(more) > PLAY_CHANGELOG_CAP:
            break
        text = more
    return text


def ios_description(key: str) -> str:
    terms, privacy = LEGAL[key]
    return f"{T[key]['desc'].rstrip()}\n\n{terms}: {EULA}\n{privacy}: {PRIVACY}"
SUPPORT = 'https://taeskim-42.github.io/setpad-site/support.html'


def write(path: pathlib.Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + '\n', encoding='utf-8')


def main():
    ios = ROOT / 'fastlane' / 'metadata'
    # Not localized — App Store keeps one copyright line for the whole app.
    write(ios / 'copyright.txt', '2026 Darak Studio Co., Ltd.')
    play = ROOT / 'fastlane' / 'metadata' / 'android'
    for key, (ios_dir, play_dir) in LOCALES.items():
        t = T[key]
        d = ios / ios_dir
        write(d / 'name.txt', t['name'])
        write(d / 'subtitle.txt', t['subtitle'])
        write(d / 'keywords.txt', t['keywords'])
        write(d / 'description.txt', ios_description(key))
        write(d / 'release_notes.txt', release_notes(key))
        write(d / 'promotional_text.txt', t['promo'])
        write(d / 'privacy_url.txt', PRIVACY)
        write(d / 'support_url.txt', SUPPORT)
        write(d / 'marketing_url.txt', '')

        p = play / play_dir
        write(p / 'title.txt', t['name'])
        write(p / 'short_description.txt', t['short'])
        write(p / 'full_description.txt', t['desc'])
        # versionCode 는 빌드할 때 시각으로 정해진다(Fastfile) — 번호 파일 대신 default.
        write(p / 'changelogs' / 'default.txt', play_changelog(key))

    # Length limits the stores enforce. Catching them here beats a rejected upload.
    bad = []
    for key, (ios_dir, play_dir) in LOCALES.items():
        t = T[key]
        for label, value, cap in (
            (f'{key} subtitle', t['subtitle'], 30),
            (f'{key} keywords', t['keywords'], 100),
            (f'{key} description', ios_description(key), 4000),
            (f'{key} play description', t['desc'], 4000),
            (f'{key} play title', t['name'], 30),
            (f'{key} play short', t['short'], 80),
            (f'{key} promotional text', t['promo'], 170),
            (f'{key} release notes', release_notes(key), 4000),
            (f'{key} play changelog', play_changelog(key), PLAY_CHANGELOG_CAP),
        ):
            if len(value) > cap:
                bad.append(f'{label}: {len(value)} > {cap}')
    for b in bad:
        print('LIMIT', b)
    print(f'{len(LOCALES)} locales written; {len(bad)} over limit')


if __name__ == '__main__':
    main()
