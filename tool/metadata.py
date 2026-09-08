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
  notes='첫 공개입니다.\n\n· 치면 남는 세트 기록\n· 지원 기기에서 한 줄 설정 (기기 안 AI)\n· 세트마다 메모\n· 건강 앱 연동 — 애플워치가 잰 활동 칼로리\n· 8개 언어, 다크 모드',
  desc='''운동 이름을 치고, 무게와 횟수를 칩니다. 그게 전부입니다.

setpad는 루틴을 미리 짜 두는 앱이 아닙니다. 세트를 끝낸 그 순간 메모장에 적듯 숫자를 칩니다. 화면을 옮겨 다니거나 드롭다운을 고를 일이 없습니다.

■ 치면 남는다
· "벤치프레스"를 치면 운동이 열리고, "80 12"를 치면 한 세트가 남습니다
· 세트 전용 키패드 — 숫자와 +/- 뿐입니다. 2.5kg씩 올리고 내립니다
· 이전 세트와 같으면 한 번만 누르면 됩니다
· 한글은 초성만 쳐도 찾습니다. 오타가 나도 찾습니다

■ 한 줄 설정
· "벤치 80kg 100개 채우기"라고 적으면 무게와 목표를 알아서 잡습니다
· 문장은 기기 안에서 처리됩니다 — 어디로도 보내지 않습니다
· iPhone 15 Pro 이상, iOS 26 이상, Apple Intelligence 켜짐이 필요합니다
· 안 되는 기기에서도 앱은 그대로 씁니다. 이유는 앱이 알려 줍니다

■ 세트마다 메모
· 세트 아래에 그때 생각을 그대로 답니다. 여러 줄이 쌓입니다
· 눌러서 고치고, 지우기로 지웁니다 — 문서 쓰듯이

■ 건강 앱 연동
· 친 운동이 건강 앱에 운동 기록으로 남습니다
· 애플워치가 잰 활동 칼로리를 가져옵니다
· 앱이 칼로리를 지어내지 않습니다. 잰 것이 없으면 없다고 적습니다

■ 그밖에
· kg, lb, km, 분, 초 — 하는 운동에 맞는 단위를 씁니다
· 다크 모드는 시스템 설정을 따릅니다
· 한국어, 영어, 일본어, 스페인어, 태국어, 베트남어, 중국어(간체·번체)

계정을 만들지 않습니다. 광고가 없습니다. 기록은 기기에 남습니다.'''),

'en': dict(
  name='setpad',
  subtitle='Type a set. It is logged.',
  short='Type the exercise, type the weight and reps. That is the whole app.',
  keywords='workout,gym,lifting,strength,training log,workout log,bench press,squat,deadlift,sets,reps',
  notes='First release.\n\n· Sets logged by typing\n· One-line setup on supported devices (on-device AI)\n· A note under any set\n· Health app — active energy measured by Apple Watch\n· Eight languages, dark mode',
  desc='''Type the exercise, type the weight and reps. That is the whole app.

setpad is not a routine builder. The moment a set is done you type the numbers, the way you would in a notes app. No screens to move between, no dropdowns to pick.

■ Typing is logging
· Type "Bench Press" and the exercise opens; type "80 12" and a set is logged
· A keypad built for sets — digits and +/-, stepping by 2.5 kg
· Same as last set? One tap
· Search tolerates typos and matches partial words

■ One-line setup
· Write "bench 80kg, work up to 100 reps" and the weight and goal are filled in
· The sentence is processed on your device — it is never sent anywhere
· Requires iPhone 15 Pro or later, iOS 26 or later, Apple Intelligence on
· On other devices the app works exactly the same; it just tells you why this part is off

■ A note under any set
· Write what you were thinking, right under the set. Notes stack up
· Tap to edit, backspace to remove — like writing a document

■ Health app
· Your workout is written to the Health app as a workout
· Active energy measured by Apple Watch is read back in
· The app never invents a calorie number. If nothing measured it, it says so

■ Also
· kg, lb, km, minutes, seconds — the unit that fits what you are doing
· Dark mode follows your system setting
· English, Korean, Japanese, Spanish, Thai, Vietnamese, Chinese (Simplified and Traditional)

No account. No ads. Your log stays on your device.'''),

'ja': dict(
  name='setpad',
  subtitle='打てば残る、筋トレ記録',
  short='種目名を打ち、重量と回数を打つ。それだけのアプリです。',
  keywords='筋トレ,ジム,ウエイト,トレーニング記録,筋トレ記録,ベンチプレス,スクワット,デッドリフト,セット,回数,フィットネス',
  notes='初回リリースです。\n\n・打てば残るセット記録\n・対応端末での一行設定（端末内AI）\n・セットごとのメモ\n・ヘルスケア連携 — Apple Watchが計測した消費エネルギー\n・8言語、ダークモード',
  desc='''種目名を打ち、重量と回数を打つ。それだけのアプリです。

setpadはルーティンを組み立てるアプリではありません。セットを終えたその場で、メモ帳に書くように数字を打ちます。画面を行き来したり、ドロップダウンを選んだりする必要はありません。

■ 打てば残る
・「ベンチプレス」と打てば種目が開き、「80 12」と打てば1セットが残ります
・セット専用キーパッド — 数字と+/-だけ。2.5kg刻みで上下します
・前のセットと同じなら一度押すだけです
・入力の揺れや打ち間違いがあっても検索に引っかかります

■ 一行設定
・「ベンチ 80kg 100回まで」と書けば、重量と目標を自動で設定します
・文章は端末内で処理されます — どこにも送信しません
・iPhone 15 Pro以降、iOS 26以降、Apple Intelligenceのオンが必要です
・非対応の端末でもアプリはそのまま使えます。理由はアプリが説明します

■ セットごとのメモ
・そのとき考えたことを、セットのすぐ下に残せます。何行でも積み上がります
・タップして直し、削除で消します — 文書を書くように

■ ヘルスケア連携
・記録した運動がヘルスケアにワークアウトとして残ります
・Apple Watchが計測した消費エネルギーを読み込みます
・アプリがカロリーを推定することはありません。計測がなければ「記録なし」と表示します

■ その他
・kg、lb、km、分、秒 — 種目に合った単位を使えます
・ダークモードはシステム設定に従います
・日本語、韓国語、英語、スペイン語、タイ語、ベトナム語、中国語（簡体字・繁体字）

アカウント登録なし。広告なし。記録は端末に残ります。'''),

'es': dict(
  name='setpad',
  subtitle='Escribe la serie. Ya está.',
  short='Escribe el ejercicio, escribe el peso y las repeticiones. Eso es todo.',
  keywords='entrenamiento,gimnasio,pesas,fuerza,diario,press banca,sentadilla,peso muerto,series,fitness',
  notes='Primera versión.\n\n· Series registradas al escribir\n· Configuración en una línea en dispositivos compatibles (IA en el dispositivo)\n· Una nota bajo cualquier serie\n· App Salud — energía activa medida por el Apple Watch\n· Ocho idiomas, modo oscuro',
  desc='''Escribe el ejercicio, escribe el peso y las repeticiones. Eso es toda la app.

setpad no es un creador de rutinas. En cuanto terminas una serie escribes los números, como lo harías en una app de notas. Sin pantallas por las que navegar, sin desplegables que elegir.

■ Escribir es registrar
· Escribe "Press banca" y el ejercicio se abre; escribe "80 12" y la serie queda registrada
· Un teclado hecho para series — dígitos y +/-, en pasos de 2,5 kg
· ¿Igual que la serie anterior? Un solo toque
· La búsqueda tolera erratas y encuentra palabras parciales

■ Configuración en una línea
· Escribe "banca 80kg hasta 100 repeticiones" y el peso y el objetivo se rellenan solos
· La frase se procesa en tu dispositivo — nunca se envía a ningún sitio
· Requiere iPhone 15 Pro o posterior, iOS 26 o posterior y Apple Intelligence activado
· En otros dispositivos la app funciona igual; solo te explica por qué esta parte no está disponible

■ Una nota bajo cualquier serie
· Anota lo que estabas pensando, justo debajo de la serie. Las notas se acumulan
· Toca para editar, retroceso para borrar — como al escribir un documento

■ App Salud
· Tu entrenamiento se guarda en Salud como un entrenamiento
· Se lee la energía activa medida por el Apple Watch
· La app nunca se inventa las calorías. Si nadie las midió, lo dice

■ Además
· kg, lb, km, minutos, segundos — la unidad que corresponde a lo que haces
· El modo oscuro sigue la configuración del sistema
· Español, inglés, coreano, japonés, tailandés, vietnamita y chino (simplificado y tradicional)

Sin cuenta. Sin anuncios. Tu registro se queda en tu dispositivo.'''),

'th': dict(
  name='setpad',
  subtitle='พิมพ์เซ็ต แล้วบันทึกเลย',
  short='พิมพ์ชื่อท่า พิมพ์น้ำหนักและจำนวนครั้ง แค่นั้นทั้งแอป',
  keywords='บันทึกออกกำลังกาย,ฟิตเนส,ยกน้ำหนัก,เวทเทรนนิ่ง,สมุดบันทึก,เบนช์เพรส,สควอท,เดดลิฟต์,เซ็ต,ยิม',
  notes='เวอร์ชันแรก\n\n· บันทึกเซ็ตด้วยการพิมพ์\n· ตั้งค่าบรรทัดเดียวบนเครื่องที่รองรับ (AI ในเครื่อง)\n· โน้ตใต้เซ็ตแต่ละเซ็ต\n· เชื่อมกับแอปสุขภาพ — พลังงานที่ Apple Watch วัด\n· แปดภาษา โหมดมืด',
  desc='''พิมพ์ชื่อท่า พิมพ์น้ำหนักและจำนวนครั้ง แค่นั้นทั้งแอป

setpad ไม่ใช่แอปสร้างโปรแกรมฝึกล่วงหน้า พอจบเซ็ตก็พิมพ์ตัวเลขลงไปทันที เหมือนจดในแอปโน้ต ไม่ต้องสลับหน้าจอ ไม่ต้องเลือกจากรายการ

■ พิมพ์คือบันทึก
· พิมพ์ "เบนช์เพรส" ท่าจะเปิดขึ้น พิมพ์ "80 12" เซ็ตก็ถูกบันทึก
· แป้นพิมพ์ที่ทำมาเพื่อเซ็ต — มีแค่ตัวเลขกับ +/- ปรับทีละ 2.5 กก.
· เหมือนเซ็ตก่อนหน้าไหม แตะครั้งเดียวพอ
· ค้นหาได้แม้พิมพ์ผิดหรือพิมพ์ไม่ครบ

■ ตั้งค่าบรรทัดเดียว
· เขียนว่า "เบนช์ 80 กก. ให้ครบ 100 ครั้ง" แล้วน้ำหนักกับเป้าหมายจะถูกตั้งให้เอง
· ประโยคถูกประมวลผลในเครื่อง — ไม่ถูกส่งออกไปไหน
· ต้องใช้ iPhone 15 Pro ขึ้นไป, iOS 26 ขึ้นไป และเปิด Apple Intelligence
· เครื่องที่ไม่รองรับก็ใช้แอปได้เหมือนเดิม แอปจะบอกเหตุผลให้

■ โน้ตใต้เซ็ต
· จดสิ่งที่คิดตอนนั้นไว้ใต้เซ็ตได้เลย จดได้หลายบรรทัด
· แตะเพื่อแก้ กดลบเพื่อลบ — เหมือนเขียนเอกสาร

■ แอปสุขภาพ
· การออกกำลังกายจะถูกบันทึกลงแอปสุขภาพ
· ดึงพลังงานที่ Apple Watch วัดไว้เข้ามา
· แอปไม่เดาแคลอรีเอง ถ้าไม่มีใครวัดไว้ก็จะบอกว่าไม่มี

■ อื่น ๆ
· กก., ปอนด์, กม., นาที, วินาที — เลือกหน่วยให้ตรงกับสิ่งที่ทำ
· โหมดมืดตามการตั้งค่าของระบบ
· ไทย อังกฤษ เกาหลี ญี่ปุ่น สเปน เวียดนาม และจีน (ตัวย่อและตัวเต็ม)

ไม่ต้องสมัครบัญชี ไม่มีโฆษณา บันทึกอยู่ในเครื่องของคุณ'''),

'vi': dict(
  name='setpad',
  subtitle='Gõ một hiệp là xong',
  short='Gõ tên bài tập, gõ mức tạ và số lần. Cả ứng dụng chỉ có vậy.',
  keywords='nhật ký tập,gym,tạ,thể hình,sức mạnh,ghi chép tập luyện,đẩy ngực,squat,deadlift,hiệp,fitness',
  notes='Bản phát hành đầu tiên.\n\n· Ghi hiệp bằng cách gõ\n· Thiết lập một dòng trên máy hỗ trợ (AI trên máy)\n· Ghi chú dưới từng hiệp\n· Kết nối app Sức khoẻ — năng lượng do Apple Watch đo\n· Tám ngôn ngữ, chế độ tối',
  desc='''Gõ tên bài tập, gõ mức tạ và số lần. Cả ứng dụng chỉ có vậy.

setpad không phải công cụ dựng giáo án. Xong hiệp nào bạn gõ số ngay lúc đó, như viết vào ứng dụng ghi chú. Không phải chuyển qua lại giữa các màn hình, không phải chọn từ danh sách xổ xuống.

■ Gõ là ghi
· Gõ "Đẩy ngực" là bài tập mở ra; gõ "80 12" là một hiệp được ghi
· Bàn phím làm riêng cho hiệp — chỉ có số và +/-, bước 2,5 kg
· Giống hiệp trước? Chạm một lần
· Tìm kiếm vẫn ra kết quả dù gõ sai hoặc gõ thiếu

■ Thiết lập một dòng
· Viết "đẩy ngực 80kg cho đủ 100 lần" là mức tạ và mục tiêu tự được điền
· Câu chữ được xử lý ngay trên máy — không gửi đi đâu cả
· Cần iPhone 15 Pro trở lên, iOS 26 trở lên và bật Apple Intelligence
· Máy khác vẫn dùng ứng dụng bình thường; ứng dụng sẽ nói rõ vì sao phần này chưa dùng được

■ Ghi chú dưới từng hiệp
· Viết điều bạn đang nghĩ, ngay dưới hiệp vừa xong. Ghi chú xếp chồng lên nhau
· Chạm để sửa, xoá lùi để bỏ — như đang viết một tài liệu

■ Ứng dụng Sức khoẻ
· Buổi tập được ghi vào Sức khoẻ như một buổi tập
· Năng lượng hoạt động do Apple Watch đo được đọc về
· Ứng dụng không tự bịa ra con số calo. Không ai đo thì nó nói là chưa có

■ Ngoài ra
· kg, lb, km, phút, giây — đơn vị hợp với việc bạn đang làm
· Chế độ tối theo cài đặt hệ thống
· Tiếng Việt, Anh, Hàn, Nhật, Tây Ban Nha, Thái và Trung (giản thể, phồn thể)

Không cần tài khoản. Không quảng cáo. Nhật ký nằm trên máy của bạn.'''),

'zh-Hans': dict(
  name='setpad',
  subtitle='打一下，这组就记下了',
  short='输入动作名，输入重量和次数。整个应用就这些。',
  keywords='健身记录,举铁,力量训练,训练日志,卧推,深蹲,硬拉,组数,次数,健身房,健身',
  notes='首个版本。\n\n· 打字即记录\n· 支持机型可用一行设置（端上 AI）\n· 每组下面都能写备注\n· 接入“健康”App — 读取 Apple Watch 测得的活动能量\n· 八种语言，深色模式',
  desc='''输入动作名，输入重量和次数。整个应用就这些。

setpad 不是用来提前编排计划的。做完一组，当场把数字打上去，就像在备忘录里写字一样。不用在页面之间来回切换，也不用从下拉框里挑。

■ 打字即记录
· 输入“卧推”，动作就打开；输入“80 12”，一组就记下了
· 专为记录组数做的键盘 — 只有数字和 +/-，每次 2.5 公斤
· 和上一组一样？点一下就行
· 打错字、只打一半也能搜到

■ 一行设置
· 写“卧推 80kg 做满 100 次”，重量和目标会自动填好
· 这句话在你的设备上处理 — 不会发送到任何地方
· 需要 iPhone 15 Pro 及以上、iOS 26 及以上，并开启 Apple Intelligence
· 其他机型照常使用，应用会告诉你这部分为什么用不了

■ 每组下的备注
· 把当时的想法写在这一组下面，可以写很多行
· 点一下修改，退格删除 — 像写文档一样

■ 健康 App
· 训练会作为一次锻炼写入“健康”App
· 读取 Apple Watch 测得的活动能量
· 应用不会自己编造卡路里。没人测过，它就写“无记录”

■ 其他
· 公斤、磅、公里、分钟、秒 — 用适合当前动作的单位
· 深色模式跟随系统设置
· 简体中文、繁体中文、英语、韩语、日语、西班牙语、泰语、越南语

无需账号。没有广告。记录留在你的设备上。'''),

'zh-Hant': dict(
  name='setpad',
  subtitle='打一下，這組就記下了',
  short='輸入動作名稱，輸入重量和次數。整個 App 就這些。',
  keywords='健身紀錄,重訓,肌力訓練,訓練日誌,臥推,深蹲,硬舉,組數,次數,健身房,健身',
  notes='首個版本。\n\n· 打字即紀錄\n· 支援機型可用一行設定（裝置端 AI）\n· 每組下面都能寫備註\n· 接入「健康」App — 讀取 Apple Watch 測得的活動能量\n· 八種語言，深色模式',
  desc='''輸入動作名稱，輸入重量和次數。整個 App 就這些。

setpad 不是用來事先編排課表的。做完一組，當場把數字打上去，就像在備忘錄裡寫字一樣。不必在頁面之間來回切換，也不必從下拉選單裡挑。

■ 打字即紀錄
· 輸入「臥推」，動作就打開；輸入「80 12」，一組就記下了
· 專為紀錄組數做的鍵盤 — 只有數字和 +/-，每次 2.5 公斤
· 和上一組一樣？點一下就好
· 打錯字、只打一半也搜得到

■ 一行設定
· 寫「臥推 80kg 做滿 100 下」，重量和目標會自動填好
· 這句話在你的裝置上處理 — 不會傳送到任何地方
· 需要 iPhone 15 Pro 以上、iOS 26 以上，並開啟 Apple Intelligence
· 其他機型照常使用，App 會告訴你這部分為什麼用不了

■ 每組下的備註
· 把當時的想法寫在這一組下面，可以寫很多行
· 點一下修改，退格刪除 — 像寫文件一樣

■ 健康 App
· 訓練會以一次體能訓練寫入「健康」App
· 讀取 Apple Watch 測得的活動能量
· App 不會自己編造卡路里。沒人量過，它就寫「無紀錄」

■ 其他
· 公斤、磅、公里、分鐘、秒 — 用適合當前動作的單位
· 深色模式跟隨系統設定
· 繁體中文、簡體中文、英文、韓文、日文、西班牙文、泰文、越南文

不需帳號。沒有廣告。紀錄留在你的裝置上。'''),
}

PRIVACY = 'https://taeskim-42.github.io/setpad-site/privacy.html'
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
        write(d / 'description.txt', t['desc'])
        write(d / 'release_notes.txt', t['notes'])
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
            (f'{key} description', t['desc'], 4000),
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
