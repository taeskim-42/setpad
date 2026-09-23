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
  short='운동 이름을 치고, 무게와 횟수를 칩니다. 그게 전부입니다.',
  keywords='운동기록,헬스,웨이트,근력운동,운동일지,헬스일지,벤치프레스,스쿼트,데드리프트,세트,루틴,피트니스',
  notes='이번 업데이트\n\n· 식단 사진으로 칼로리 추정 (사진은 저장하지 않음)\n· 체육관 연결, 루틴 수신, PT 예약\n· 로그인 유지와 앱 안 계정 삭제\n· 스티커 출석과 앱 링크',
  desc='''운동 이름을 치고, 무게와 횟수를 칩니다. 그게 전부입니다.

setpad는 루틴을 미리 짜 두는 앱이 아닙니다. 세트를 끝낸 그 순간 메모장에 적듯 숫자를 칩니다. 화면을 옮겨 다니거나 드롭다운을 고를 일이 없습니다.

■ 치면 남는다
· "벤치프레스"를 치면 운동이 열리고, "80 12"를 치면 한 세트가 남습니다
· 세트 전용 키패드 — 숫자와 +/- 뿐입니다. 2.5kg씩 올리고 내립니다
· 이전 세트와 같으면 한 번만 누르면 됩니다
· 한글은 초성만 쳐도 찾습니다. 오타가 나도 찾습니다

■ 한 줄 설정
· "벤치 80kg 100개 채우기"라고 적으면 무게와 목표를 알아서 잡습니다
· 문장은 서버의 AI가 해석합니다. 문장은 서버에 저장하지 않습니다
· 인터넷이 없거나 해석이 안 되면 친 그대로 이름으로 남습니다 — 기록은 막히지 않습니다

■ 세트마다 메모
· 세트 아래에 그때 생각을 그대로 답니다. 여러 줄이 쌓입니다
· 눌러서 고치고, 지우기로 지웁니다 — 문서 쓰듯이

■ 건강 앱 연동
· 친 운동이 건강 앱에 운동 기록으로 남습니다
· 워치가 잰 활동 칼로리를 가져옵니다 (Apple 건강, 헬스 커넥트)
· 타바타 휴식 중 워치 심박이 그 라운드 최고치보다 25bpm 내려오면 휴식을 끝내고 다음 라운드를 알립니다. 쉬는 동안 ♥ 지금 → 목표가 보입니다
· 건강 앱에서 읽은 값은 기기 밖으로 나가지 않습니다
· 앱이 칼로리를 지어내지 않습니다. 잰 것이 없으면 없다고 적습니다

■ 그밖에
· kg, lb, km, 분, 초 — 하는 운동에 맞는 단위를 씁니다
· 다크 모드는 시스템 설정을 따릅니다
· 한국어, 영어, 일본어, 스페인어, 태국어, 베트남어, 중국어(간체·번체)

■ 식단·같이 하기
· 식단을 사진이나 글로 남깁니다. 열량을 모르면 모른다고 적습니다
· 그날 먹은 것과 운동으로 쓴 것을 한 줄로 봅니다
· 같이 하기: 코드로 연결해 서로의 기록을 봅니다. 상대 기록은 읽기 전용입니다
· 타바타와 박자를 둘이 같은 순간에 시작합니다. 기구 하나를 번갈아 쓰는 교대도 됩니다
· 공동 루틴: 링크로 초대해 다음 운동을 함께 정하고, 같은 버전에 동의한 뒤 시작합니다

혼자 기록하는 데는 계정이 필요 없습니다. 도장 연결, 같이 하기, 공동 루틴, 구독에는 로그인이 필요합니다. 광고가 없습니다. 기록은 기기에 남고, 도장에 연결한 기록과 공유하기로 한 것만 서버로 갑니다.'''),

'en': dict(
  name='setpad',
  subtitle='Type a set. It is logged.',
  short='Type the exercise, type the weight and reps. That is the whole app.',
  keywords='workout,gym,lifting,strength,training log,workout log,bench press,squat,deadlift,sets,reps',
  notes='In this update\n\n· Estimate calories from a meal photo (photos are not stored)\n· Connect to a gym, receive routines, and book PT sessions\n· Persistent sign-in and in-app account deletion\n· Sticker check-ins and app links',
  desc='''Type the exercise, type the weight and reps. That is the whole app.

setpad is not a routine builder. The moment a set is done you type the numbers, the way you would in a notes app. No screens to move between, no dropdowns to pick.

■ Typing is logging
· Type "Bench Press" and the exercise opens; type "80 12" and a set is logged
· A keypad built for sets — digits and +/-, stepping by 2.5 kg
· Same as last set? One tap
· Search tolerates typos and matches partial words

■ One-line setup
· Write "bench 80kg, work up to 100 reps" and the weight and goal are filled in
· The sentence is interpreted by AI on our server. The sentence is not stored there
· Offline, or when it cannot be interpreted, what you typed simply becomes the name — logging is never blocked

■ A note under any set
· Write what you were thinking, right under the set. Notes stack up
· Tap to edit, backspace to remove — like writing a document

■ Health app
· Your workout is written to the Health app as a workout
· Active energy measured by your watch is read back in (Apple Health, Health Connect)
· During a Tabata rest, once your watch heart rate is 25 bpm below that round's peak, the rest ends and the next round is signalled. While resting you see ♥ now → target
· What is read from your health app never leaves the device
· The app never invents a calorie number. If nothing measured it, it says so

■ Also
· kg, lb, km, minutes, seconds — the unit that fits what you are doing
· Dark mode follows your system setting
· English, Korean, Japanese, Spanish, Thai, Vietnamese, Chinese (Simplified and Traditional)

■ Meals, together
· Log meals by photo or as text. When the calories are unknown, it says unknown
· See the day's intake and exercise energy in one line
· Together: connect with a code to see each other's log. Your partner's log is read-only
· Start a Tabata or a tempo on both phones at the same moment — or take turns on one machine
· Shared plans: invite by link, decide the next workout together, agree on the same version, then start

Logging on your own needs no account. Gym links, working out together, shared plans and subscriptions need sign-in. No ads. Your log stays on your device; only gym-linked records and what you choose to share go to the server.'''),

'ja': dict(
  name='setpad',
  subtitle='打てば残る、筋トレ記録',
  short='種目名を打ち、重量と回数を打つ。それだけのアプリです。',
  keywords='筋トレ,ジム,ウエイト,トレーニング記録,筋トレ記録,ベンチプレス,スクワット,デッドリフト,セット,回数,フィットネス',
  notes='今回のアップデート\n\n・食事写真からカロリーを推定（写真は保存しません）\n・ジム連携、ルーティン受信、PT予約\n・ログイン保持とアプリ内アカウント削除\n・ステッカーでのチェックインとアプリリンク',
  desc='''種目名を打ち、重量と回数を打つ。それだけのアプリです。

setpadはルーティンを組み立てるアプリではありません。セットを終えたその場で、メモ帳に書くように数字を打ちます。画面を行き来したり、ドロップダウンを選んだりする必要はありません。

■ 打てば残る
・「ベンチプレス」と打てば種目が開き、「80 12」と打てば1セットが残ります
・セット専用キーパッド — 数字と+/-だけ。2.5kg刻みで上下します
・前のセットと同じなら一度押すだけです
・入力の揺れや打ち間違いがあっても検索に引っかかります

■ 一行設定
・「ベンチ 80kg 100回まで」と書けば、重量と目標を自動で設定します
・文章はサーバーのAIが解釈します。文章はサーバーに保存しません
・オフラインや解釈できないときは、入力したままが種目名になります — 記録は止まりません

■ セットごとのメモ
・そのとき考えたことを、セットのすぐ下に残せます。何行でも積み上がります
・タップして直し、削除で消します — 文書を書くように

■ ヘルスケア連携
・記録した運動がヘルスケアにワークアウトとして残ります
・ウォッチが計測した消費エネルギーを読み込みます(Apple ヘルスケア、ヘルスコネクト)
・タバタの休憩中、ウォッチの心拍がそのラウンドの最高値より 25bpm 下がると休憩を終え、次のラウンドを知らせます。休憩中は ♥ 現在 → 目標 が表示されます
・ヘルスケアから読み取った値は端末の外に出ません
・アプリがカロリーを推定することはありません。計測がなければ「記録なし」と表示します

■ その他
・kg、lb、km、分、秒 — 種目に合った単位を使えます
・ダークモードはシステム設定に従います
・日本語、韓国語、英語、スペイン語、タイ語、ベトナム語、中国語（簡体字・繁体字）

■ 食事・一緒に
・食事を写真またはテキストで記録。カロリーが不明なら不明と表示します
・その日の摂取と運動消費を1行で見られます
・一緒に: コードでつながってお互いの記録を見ます。相手の記録は閲覧のみです
・タバタやテンポを2台で同じ瞬間にスタート。器具1台を交代で使うこともできます
・共同ルーティン: リンクで招待して次の運動を一緒に決め、同じバージョンに合意してから始めます

一人で記録するだけならアカウントは不要です。ジム連携、一緒に、共同ルーティン、サブスクリプションにはログインが必要です。広告なし。記録は端末に残り、ジムに連携した記録と共有すると決めたものだけがサーバーに送られます。'''),

'es': dict(
  name='setpad',
  subtitle='Escribe la serie. Ya está.',
  short='Escribe el ejercicio, escribe el peso y las repeticiones. Eso es todo.',
  keywords='entrenamiento,gimnasio,pesas,fuerza,diario,press banca,sentadilla,peso muerto,series,fitness',
  notes='En esta actualización\n\n· Estimación de calorías a partir de una foto de comida (la foto no se guarda)\n· Conexión con el gimnasio, rutinas y reservas de PT\n· Inicio de sesión persistente y eliminación de la cuenta en la app\n· Registro con pegatinas y enlaces a la app',
  desc='''Escribe el ejercicio, escribe el peso y las repeticiones. Eso es toda la app.

setpad no es un creador de rutinas. En cuanto terminas una serie escribes los números, como lo harías en una app de notas. Sin pantallas por las que navegar, sin desplegables que elegir.

■ Escribir es registrar
· Escribe "Press banca" y el ejercicio se abre; escribe "80 12" y la serie queda registrada
· Un teclado hecho para series — dígitos y +/-, en pasos de 2,5 kg
· ¿Igual que la serie anterior? Un solo toque
· La búsqueda tolera erratas y encuentra palabras parciales

■ Configuración en una línea
· Escribe "banca 80kg hasta 100 repeticiones" y el peso y el objetivo se rellenan solos
· La frase la interpreta una IA en nuestro servidor. La frase no se guarda allí
· Sin conexión, o si no se puede interpretar, lo que escribiste queda como nombre — el registro nunca se bloquea

■ Una nota bajo cualquier serie
· Anota lo que estabas pensando, justo debajo de la serie. Las notas se acumulan
· Toca para editar, retroceso para borrar — como al escribir un documento

■ App Salud
· Tu entrenamiento se guarda en Salud como un entrenamiento
· Se lee la energía activa medida por tu reloj (Salud de Apple, Health Connect)
· En el descanso de un Tabata, cuando el pulso del reloj baja 25 lpm del máximo de esa ronda, el descanso termina y se avisa la siguiente ronda. Mientras descansas ves ♥ ahora → objetivo
· Lo que se lee de la app de salud nunca sale del dispositivo
· La app nunca se inventa las calorías. Si nadie las midió, lo dice

■ Además
· kg, lb, km, minutos, segundos — la unidad que corresponde a lo que haces
· El modo oscuro sigue la configuración del sistema
· Español, inglés, coreano, japonés, tailandés, vietnamita y chino (simplificado y tradicional)

■ Comidas, juntos
· Registra comidas con foto o texto. Si no se conocen las calorías, lo dice
· Mira la ingesta del día y la energía del ejercicio en una línea
· Juntos: conéctate con un código para ver el registro del otro. El de tu compañero es de solo lectura
· Empezad un Tabata o un tempo en los dos móviles en el mismo instante, o por turnos en una máquina
· Planes compartidos: invita por enlace, decidid juntos el próximo entrenamiento, acordad la misma versión y empezad

Para registrar por tu cuenta no hace falta cuenta. Los gimnasios, entrenar juntos, los planes compartidos y las suscripciones requieren iniciar sesión. Sin anuncios. Tu registro se queda en tu dispositivo; solo van al servidor los registros vinculados a un gimnasio y lo que decidas compartir.'''),

'th': dict(
  name='setpad',
  subtitle='พิมพ์เซ็ต แล้วบันทึกเลย',
  short='พิมพ์ชื่อท่า พิมพ์น้ำหนักและจำนวนครั้ง แค่นั้นทั้งแอป',
  keywords='บันทึกออกกำลังกาย,ฟิตเนส,ยกน้ำหนัก,เวทเทรนนิ่ง,สมุดบันทึก,เบนช์เพรส,สควอท,เดดลิฟต์,เซ็ต,ยิม',
  notes='ในการอัปเดตนี้\n\n· ประเมินแคลอรีจากภาพอาหาร (ไม่จัดเก็บภาพ)\n· เชื่อมต่อยิม รับโปรแกรม และจอง PT\n· คงสถานะการเข้าสู่ระบบและลบบัญชีในแอป\n· เช็กอินด้วยสติกเกอร์และลิงก์เข้าแอป',
  desc='''พิมพ์ชื่อท่า พิมพ์น้ำหนักและจำนวนครั้ง แค่นั้นทั้งแอป

setpad ไม่ใช่แอปสร้างโปรแกรมฝึกล่วงหน้า พอจบเซ็ตก็พิมพ์ตัวเลขลงไปทันที เหมือนจดในแอปโน้ต ไม่ต้องสลับหน้าจอ ไม่ต้องเลือกจากรายการ

■ พิมพ์คือบันทึก
· พิมพ์ "เบนช์เพรส" ท่าจะเปิดขึ้น พิมพ์ "80 12" เซ็ตก็ถูกบันทึก
· แป้นพิมพ์ที่ทำมาเพื่อเซ็ต — มีแค่ตัวเลขกับ +/- ปรับทีละ 2.5 กก.
· เหมือนเซ็ตก่อนหน้าไหม แตะครั้งเดียวพอ
· ค้นหาได้แม้พิมพ์ผิดหรือพิมพ์ไม่ครบ

■ ตั้งค่าบรรทัดเดียว
· เขียนว่า "เบนช์ 80 กก. ให้ครบ 100 ครั้ง" แล้วน้ำหนักกับเป้าหมายจะถูกตั้งให้เอง
· ประโยคถูกตีความโดย AI บนเซิร์ฟเวอร์ของเรา และไม่ถูกเก็บไว้ที่นั่น
· เมื่อออฟไลน์หรือตีความไม่ได้ สิ่งที่พิมพ์จะกลายเป็นชื่อท่าตามนั้น — การบันทึกไม่ถูกขวาง

■ โน้ตใต้เซ็ต
· จดสิ่งที่คิดตอนนั้นไว้ใต้เซ็ตได้เลย จดได้หลายบรรทัด
· แตะเพื่อแก้ กดลบเพื่อลบ — เหมือนเขียนเอกสาร

■ แอปสุขภาพ
· การออกกำลังกายจะถูกบันทึกลงแอปสุขภาพ
· ดึงพลังงานที่นาฬิกาวัดไว้เข้ามา (Apple Health, Health Connect)
· ระหว่างพักในทาบาตะ เมื่อหัวใจที่นาฬิกาวัดได้ต่ำกว่าค่าสูงสุดของรอบนั้น 25 bpm จะจบการพักและแจ้งรอบถัดไป ระหว่างพักจะเห็น ♥ ปัจจุบัน → เป้าหมาย
· ค่าที่อ่านจากแอปสุขภาพจะไม่ออกจากอุปกรณ์
· แอปไม่เดาแคลอรีเอง ถ้าไม่มีใครวัดไว้ก็จะบอกว่าไม่มี

■ อื่น ๆ
· กก., ปอนด์, กม., นาที, วินาที — เลือกหน่วยให้ตรงกับสิ่งที่ทำ
· โหมดมืดตามการตั้งค่าของระบบ
· ไทย อังกฤษ เกาหลี ญี่ปุ่น สเปน เวียดนาม และจีน (ตัวย่อและตัวเต็ม)

■ อาหาร และออกกำลังด้วยกัน
· บันทึกมื้ออาหารด้วยรูปหรือข้อความ ถ้าไม่ทราบแคลอรีก็จะบอกว่าไม่ทราบ
· ดูการกินและพลังงานที่ใช้ออกกำลังของวันนั้นในบรรทัดเดียว
· ด้วยกัน: เชื่อมต่อด้วยรหัสเพื่อดูบันทึกของกันและกัน บันทึกของอีกฝ่ายอ่านได้อย่างเดียว
· เริ่มทาบาตะหรือจังหวะบนสองเครื่องในวินาทีเดียวกัน หรือสลับกันใช้เครื่องเดียว
· แผนร่วม: เชิญด้วยลิงก์ ตกลงการออกกำลังครั้งถัดไปด้วยกัน ยอมรับเวอร์ชันเดียวกัน แล้วเริ่ม

การบันทึกคนเดียวไม่ต้องมีบัญชี การเชื่อมยิม การออกกำลังด้วยกัน แผนร่วม และการสมัครสมาชิกต้องเข้าสู่ระบบ ไม่มีโฆษณา บันทึกอยู่ในเครื่องของคุณ มีเพียงบันทึกที่เชื่อมกับยิมและสิ่งที่คุณเลือกแชร์เท่านั้นที่ส่งไปเซิร์ฟเวอร์'''),

'vi': dict(
  name='setpad',
  subtitle='Gõ một hiệp là xong',
  short='Gõ tên bài tập, gõ mức tạ và số lần. Cả ứng dụng chỉ có vậy.',
  keywords='nhật ký tập,gym,tạ,thể hình,sức mạnh,ghi chép tập luyện,đẩy ngực,squat,deadlift,hiệp,fitness',
  notes='Trong bản cập nhật này\n\n· Ước tính calo từ ảnh bữa ăn (không lưu ảnh)\n· Kết nối phòng tập, nhận giáo án và đặt lịch PT\n· Duy trì đăng nhập và xoá tài khoản trong ứng dụng\n· Điểm danh bằng nhãn dán và liên kết ứng dụng',
  desc='''Gõ tên bài tập, gõ mức tạ và số lần. Cả ứng dụng chỉ có vậy.

setpad không phải công cụ dựng giáo án. Xong hiệp nào bạn gõ số ngay lúc đó, như viết vào ứng dụng ghi chú. Không phải chuyển qua lại giữa các màn hình, không phải chọn từ danh sách xổ xuống.

■ Gõ là ghi
· Gõ "Đẩy ngực" là bài tập mở ra; gõ "80 12" là một hiệp được ghi
· Bàn phím làm riêng cho hiệp — chỉ có số và +/-, bước 2,5 kg
· Giống hiệp trước? Chạm một lần
· Tìm kiếm vẫn ra kết quả dù gõ sai hoặc gõ thiếu

■ Thiết lập một dòng
· Viết "đẩy ngực 80kg cho đủ 100 lần" là mức tạ và mục tiêu tự được điền
· Câu chữ được AI trên máy chủ của chúng tôi diễn giải. Câu chữ không được lưu ở đó
· Khi ngoại tuyến hoặc không diễn giải được, điều bạn gõ sẽ thành tên bài tập — việc ghi không bao giờ bị chặn

■ Ghi chú dưới từng hiệp
· Viết điều bạn đang nghĩ, ngay dưới hiệp vừa xong. Ghi chú xếp chồng lên nhau
· Chạm để sửa, xoá lùi để bỏ — như đang viết một tài liệu

■ Ứng dụng Sức khoẻ
· Buổi tập được ghi vào Sức khoẻ như một buổi tập
· Năng lượng hoạt động do đồng hồ đo được đọc về (Apple Health, Health Connect)
· Khi nghỉ Tabata, nhịp tim từ đồng hồ giảm 25 bpm so với mức cao nhất của hiệp đó thì thời gian nghỉ kết thúc và hiệp tiếp theo được báo. Khi nghỉ bạn thấy ♥ hiện tại → mục tiêu
· Dữ liệu đọc từ ứng dụng sức khỏe không rời khỏi thiết bị
· Ứng dụng không tự bịa ra con số calo. Không ai đo thì nó nói là chưa có

■ Ngoài ra
· kg, lb, km, phút, giây — đơn vị hợp với việc bạn đang làm
· Chế độ tối theo cài đặt hệ thống
· Tiếng Việt, Anh, Hàn, Nhật, Tây Ban Nha, Thái và Trung (giản thể, phồn thể)

■ Bữa ăn, tập cùng nhau
· Ghi bữa ăn bằng ảnh hoặc chữ. Khi chưa rõ calo, ứng dụng ghi là chưa rõ
· Xem lượng nạp và năng lượng tập trong ngày trên một dòng
· Cùng nhau: kết nối bằng mã để xem ghi chép của nhau. Ghi chép của bạn tập chỉ để xem
· Bắt đầu Tabata hoặc nhịp trên hai máy cùng một lúc — hoặc luân phiên trên một máy tập
· Kế hoạch chung: mời bằng liên kết, cùng quyết định buổi tập tới, thống nhất cùng một phiên bản rồi bắt đầu

Tự ghi một mình thì không cần tài khoản. Liên kết phòng tập, tập cùng nhau, kế hoạch chung và gói đăng ký cần đăng nhập. Không quảng cáo. Nhật ký nằm trên máy của bạn; chỉ các bản ghi liên kết với phòng tập và những gì bạn chọn chia sẻ mới lên máy chủ.'''),

'zh-Hans': dict(
  name='setpad',
  subtitle='打一下，这组就记下了',
  short='输入动作名，输入重量和次数。整个应用就这些。',
  keywords='健身记录,举铁,力量训练,训练日志,卧推,深蹲,硬拉,组数,次数,健身房,健身',
  notes='本次更新\n\n· 根据餐食照片估算热量（不保存照片）\n· 连接健身房、接收训练计划并预约私教\n· 保持登录及在 App 内删除账户\n· 贴纸签到与 App 链接',
  desc='''输入动作名，输入重量和次数。整个应用就这些。

setpad 不是用来提前编排计划的。做完一组，当场把数字打上去，就像在备忘录里写字一样。不用在页面之间来回切换，也不用从下拉框里挑。

■ 打字即记录
· 输入“卧推”，动作就打开；输入“80 12”，一组就记下了
· 专为记录组数做的键盘 — 只有数字和 +/-，每次 2.5 公斤
· 和上一组一样？点一下就行
· 打错字、只打一半也能搜到

■ 一行设置
· 写“卧推 80kg 做满 100 次”，重量和目标会自动填好
· 这句话由我们服务器上的 AI 解析，句子不会保存在服务器上
· 离线或无法解析时，你输入的内容会原样成为动作名 — 记录不会被挡住

■ 每组下的备注
· 把当时的想法写在这一组下面，可以写很多行
· 点一下修改，退格删除 — 像写文档一样

■ 健康 App
· 训练会作为一次锻炼写入“健康”App
· 读取手表测得的活动能量(Apple 健康、Health Connect)
· Tabata 休息期间,手表心率比该轮最高值低 25 bpm 时,休息结束并提示下一轮。休息时显示 ♥ 当前 → 目标
· 从健康应用读取的数据不会离开设备
· 应用不会自己编造卡路里。没人测过，它就写“无记录”

■ 其他
· 公斤、磅、公里、分钟、秒 — 用适合当前动作的单位
· 深色模式跟随系统设置
· 简体中文、繁体中文、英语、韩语、日语、西班牙语、泰语、越南语

■ 饮食、一起练
· 用照片或文字记录饮食。不知道热量时就标为未知
· 用一行查看当天的摄入和运动消耗
· 一起练：用代码连接，查看彼此的记录。对方的记录只读
· 两台手机在同一瞬间开始 Tabata 或节拍，也可以轮流使用一台器械
· 共同计划：用链接邀请，一起决定下一次训练，同意同一版本后开始

独自记录不需要账号。连接健身房、一起练、共同计划和订阅需要登录。没有广告。记录留在你的设备上，只有与健身房关联的记录和你选择共享的内容会发送到服务器。'''),

'zh-Hant': dict(
  name='setpad',
  subtitle='打一下，這組就記下了',
  short='輸入動作名稱，輸入重量和次數。整個 App 就這些。',
  keywords='健身紀錄,重訓,肌力訓練,訓練日誌,臥推,深蹲,硬舉,組數,次數,健身房,健身',
  notes='本次更新\n\n· 根據餐點照片估算熱量（不儲存照片）\n· 連結健身房、接收訓練課表並預約教練課\n· 保持登入及在 App 內刪除帳號\n· 貼紙簽到與 App 連結',
  desc='''輸入動作名稱，輸入重量和次數。整個 App 就這些。

setpad 不是用來事先編排課表的。做完一組，當場把數字打上去，就像在備忘錄裡寫字一樣。不必在頁面之間來回切換，也不必從下拉選單裡挑。

■ 打字即紀錄
· 輸入「臥推」，動作就打開；輸入「80 12」，一組就記下了
· 專為紀錄組數做的鍵盤 — 只有數字和 +/-，每次 2.5 公斤
· 和上一組一樣？點一下就好
· 打錯字、只打一半也搜得到

■ 一行設定
· 寫「臥推 80kg 做滿 100 下」，重量和目標會自動填好
· 這句話由我們伺服器上的 AI 解析，句子不會儲存在伺服器上
· 離線或無法解析時，你輸入的內容會原樣成為動作名稱 — 紀錄不會被擋住

■ 每組下的備註
· 把當時的想法寫在這一組下面，可以寫很多行
· 點一下修改，退格刪除 — 像寫文件一樣

■ 健康 App
· 訓練會以一次體能訓練寫入「健康」App
· 讀取手錶測得的活動能量(Apple 健康、Health Connect)
· Tabata 休息期間,手錶心率比該輪最高值低 25 bpm 時,休息結束並提示下一輪。休息時顯示 ♥ 目前 → 目標
· 從健康 App 讀取的資料不會離開裝置
· App 不會自己編造卡路里。沒人量過，它就寫「無紀錄」

■ 其他
· 公斤、磅、公里、分鐘、秒 — 用適合當前動作的單位
· 深色模式跟隨系統設定
· 繁體中文、簡體中文、英文、韓文、日文、西班牙文、泰文、越南文

■ 飲食、一起練
· 用照片或文字記錄飲食。不知道熱量時就標為未知
· 用一行查看當天的攝取和運動消耗
· 一起練：用代碼連線，查看彼此的紀錄。對方的紀錄唯讀
· 兩支手機在同一瞬間開始 Tabata 或節拍，也可以輪流使用一台器材
· 共同計畫：用連結邀請，一起決定下一次訓練，同意同一版本後開始

獨自記錄不需要帳號。連結健身房、一起練、共同計畫和訂閱需要登入。沒有廣告。紀錄留在你的裝置上，只有與健身房關聯的紀錄和你選擇分享的內容會傳送到伺服器。'''),
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


# 이번 버전에 더해진 것. 출시 노트의 머리말 바로 아래에 끼운다.
NEWS = {
    'ko': ['오늘 한 모든 세트를 한 화면에 — 칸을 눌러 바로 고칩니다',
           '식단을 글로도 기록하고, 먹은 양으로 열량을 계산합니다',
           '같이 하기: 코드로 연결해 서로의 기록을 보고, 링크로 초대해 운동 계획을 함께 짭니다',
           '같이 하는 타이머: 타바타·bpm 을 두 폰에서 같은 순간에 시작하고, 쉬는 동안 서로의 횟수를 봅니다'],
    'en': ['Every set you did today on one screen — tap a cell to fix it',
           'Log meals as text, and calculate calories from how much you ate',
           'Together: connect with a code to see each other\'s log, and plan workouts together by invite link',
           'Shared timer: start Tabata or bpm on both phones at the same moment and see each other\'s reps while you rest'],
    'ja': ['今日行った全セットを1画面に — セルをタップしてすぐ修正',
           '食事をテキストでも記録し、食べた量からカロリーを計算',
           '一緒に: コードでつながってお互いの記録を見たり、リンクで招待して運動計画を一緒に作成',
           '一緒にタイマー: タバタ・bpmを2台で同じ瞬間に始め、休憩中にお互いの回数を見られます'],
    'es': ['Todas las series de hoy en una pantalla: toca una celda para corregirla',
           'Registra comidas como texto y calcula las calorías según lo que comiste',
           'Juntos: conéctate con un código para ver el registro del otro y planifica entrenamientos por enlace',
           'Temporizador compartido: empezad Tabata o bpm en el mismo instante y ved las repeticiones del otro al descansar'],
    'th': ['ทุกเซ็ตของวันนี้ในหน้าจอเดียว — แตะช่องเพื่อแก้ไขได้ทันที',
           'บันทึกมื้ออาหารเป็นข้อความ และคำนวณแคลอรีจากปริมาณที่กิน',
           'ด้วยกัน: เชื่อมต่อด้วยรหัสเพื่อดูบันทึกของกันและกัน และวางแผนออกกำลังร่วมกันผ่านลิงก์เชิญ',
           'ตัวจับเวลาร่วม: เริ่มทาบาตะหรือ bpm พร้อมกันบนสองเครื่อง และเห็นจำนวนครั้งของกันและกันตอนพัก'],
    'vi': ['Mọi hiệp hôm nay trên một màn hình — chạm vào ô để sửa ngay',
           'Ghi bữa ăn bằng chữ và tính calo theo lượng đã ăn',
           'Cùng nhau: kết nối bằng mã để xem ghi chép của nhau, và cùng lên kế hoạch tập qua liên kết mời',
           'Hẹn giờ chung: bắt đầu Tabata hoặc bpm cùng lúc trên hai máy và xem số lần của nhau khi nghỉ'],
    'zh-Hans': ['今天做的所有组都在一屏 — 点格子即可修改',
                '用文字记录饮食，并按实际食用量计算热量',
                '一起练：用代码连接查看彼此的记录，并通过邀请链接一起制定训练计划',
           '共同计时：两台手机同时开始 Tabata 或 bpm，休息时查看彼此的次数'],
    'zh-Hant': ['今天做的所有組都在一個畫面 — 點格子即可修改',
                '用文字記錄飲食，並依實際食用量計算熱量',
                '一起練：用代碼連線查看彼此的紀錄，並透過邀請連結一起制定訓練計畫',
           '共同計時：兩支手機同時開始 Tabata 或 bpm，休息時查看彼此的次數'],
}


def release_notes(key: str) -> str:
    lines = T[key]['notes'].rstrip().split('\n')
    # 머리말과 빈 줄 다음에 끼운다. 이미 있는 항목은 그대로 둔다.
    at = next((i for i, line in enumerate(lines) if line.startswith('·')), len(lines))
    return '\n'.join(lines[:at] + [f'· {n}' for n in NEWS[key]] + lines[at:])


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
        write(d / 'privacy_url.txt', PRIVACY)
        write(d / 'support_url.txt', SUPPORT)
        write(d / 'marketing_url.txt', '')

        p = play / play_dir
        write(p / 'title.txt', t['name'])
        write(p / 'short_description.txt', t['short'])
        write(p / 'full_description.txt', t['desc'])

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
        ):
            if len(value) > cap:
                bad.append(f'{label}: {len(value)} > {cap}')
    for b in bad:
        print('LIMIT', b)
    print(f'{len(LOCALES)} locales written; {len(bad)} over limit')


if __name__ == '__main__':
    main()
