# 앱 개인정보(데이터 수집 신고)를 코드가 실제로 하는 대로 게시한다.
#
# 1.3.0 까지는 "수집하지 않음" 이었다. 이제는 아니다 — 로그인(이름·계정 id), 구매,
# 기기 id, 같이 하기·체육관으로 가는 운동 기록, 체육관으로 가는 끼니, AI(DeepSeek)로
# 가는 글·식단 사진·기록 질문이 서버를 지난다. 한 줄마다 근거가 되는 코드 자리를 적었다.
# 근거와 판단(사실/해석)은 scratchpad 의 app-privacy-answers.md 에 풀어 두었다.
#
# **공개 App Store Connect API 에는 이 자리가 없다.** /v1/appDataUsages 는
# PATH_ERROR 로 답하고, 앱 리소스의 관계 목록에도 안 들어 있다. 실제 자리는
# 콘솔이 쓰는 iris API 이고, spaceship 의 tunes 클라이언트가 그리로 간다.
#
#   DRY_RUN=1 ruby tool/app_privacy.rb   # 무엇을 올릴지 찍기만 한다 (그물 없음)
#   ruby tool/app_privacy.rb             # 기존 신고를 지우고 아래 것으로 바꾼 뒤 게시
#
# 올리는 방식은 fastlane 의 upload_app_privacy_details_to_app_store 와 같다(기존 항목을
# 모두 지우고 종류 × 목적마다 한 줄). 그 액션은 Apple ID 로그인을 요구해서 API 키로
# 도는 이 스크립트를 따로 둔다.

APP_ID = '6757940370'

# 추적(DATA_USED_TO_TRACK_YOU)은 어디에도 없다 — 광고·분석 SDK 가 없고(pubspec.yaml),
# 다른 회사의 데이터와 합치거나 데이터 브로커에 넘기지 않는다. 목적은 모두 앱 기능.
LINKED = 'DATA_LINKED_TO_YOU'
NOT_LINKED = 'DATA_NOT_LINKED_TO_YOU'
FUNCTION = 'APP_FUNCTIONALITY'

USAGES = [
  # 로그인 이름(최대 20자) — 같이 하는 사람과 체육관이 본다.
  # gymdojo app/api/auth/app/route.ts (nickname), lib/identity.ts (users.nickname)
  { category: 'NAME', purposes: [FUNCTION], protection: LINKED },
  # Apple·Google 계정 고유번호(sub)와 우리 사용자 id. 이메일은 읽지도 저장하지도 않는다
  # (lib/oauth.ts verifyIdentityToken 은 sub 만, lib/sign_in.dart Apple 범위는 fullName 만).
  { category: 'USER_ID', purposes: [FUNCTION], protection: LINKED },
  # 앱이 처음 켤 때 만드는 무작위 id(lib/notes.dart deviceId) — 로그인 전 AI 한도와 이 기기의
  # 원판 지갑을 센다(record_query_usage·plate_ledger 의 'device:<id>'). 계정과 잇는 줄은 없다.
  { category: 'DEVICE_ID', purposes: [FUNCTION], protection: NOT_LINKED },
  # 이용권: 스토어 구매 번호·상품·만료일(entitlements, 계정에 붙음 — 로그인해야 산다).
  { category: 'PURCHASE_HISTORY', purposes: [FUNCTION], protection: LINKED },
  # 운동 기록: 체육관 연결(/api/workouts), 같이 하기 기록·문서, 건네기 링크, 하루 원판의 세트 수.
  { category: 'FITNESS', purposes: [FUNCTION], protection: LINKED },
  # 건강: 사람이 적은 식단(글·음식·양·열량)이 연결한 체육관으로 간다(GymLink.saveMeal).
  # Apple 건강·헬스 커넥트에서 읽은 값(활동 칼로리·심박)은 기기 밖으로 나가지 않는다.
  { category: 'HEALTH', purposes: [FUNCTION], protection: LINKED },
  # 식단 사진: 촬영 정보를 떼고 우리 서버를 거쳐 DeepSeek 로 — 서버는 저장하지 않는다.
  # 모델 요청에는 사람을 가리키는 값이 없다(lib/model-json.ts).
  { category: 'PHOTOS_OR_VIDEOS', purposes: [FUNCTION], protection: NOT_LINKED },
  # 기록 질문(기록 검색창에 제출한 문장)은 운동 이름 목록과 함께 DeepSeek 로 — 저장하지 않는다.
  { category: 'SEARCH_HISTORY', purposes: [FUNCTION], protection: NOT_LINKED },
  # 세트 메모·같이 고친 기록의 글·건넨 기록, 그리고 AI 로 가는 한 줄 설정·식단 글.
  # 앞의 것이 계정에 붙어 서버에 남으므로 이 종류는 '연결됨'.
  { category: 'OTHER_USER_CONTENT', purposes: [FUNCTION], protection: LINKED },
  # 원판 장부: 계정 지갑에 질문마다 쓴 양이 남는다(lib/plates.ts plate_ledger).
  { category: 'PRODUCT_INTERACTION', purposes: [FUNCTION], protection: LINKED },
  # 체육관 회원 신청과 PT 예약(/api/members, /api/bookings).
  { category: 'OTHER_DATA', purposes: [FUNCTION], protection: LINKED },
].freeze

# 안 모으는 것(여기 없는 종류): 이메일, 전화, 주소, 위치(사진의 위치도 뗀다), 연락처,
# 결제 수단, 광고 데이터, 충돌·성능·진단(수집 SDK 없음), 원판 장부 밖의 사용 데이터(분석 없음).

if ENV['DRY_RUN']
  USAGES.each do |u|
    u[:purposes].each { |p| puts "#{u[:category]} · #{p} · #{u[:protection]}" }
  end
  puts "#{USAGES.size}개 종류, 추적 없음 — 올리지 않았다 (DRY_RUN)"
  exit
end

require 'spaceship'

key_id = ENV.fetch('ASC_KEY_ID')
token = Spaceship::ConnectAPI::Token.create(
  key_id: key_id,
  issuer_id: ENV.fetch('ASC_ISSUER_ID'),
  filepath: ENV.fetch('ASC_KEY_PATH',
                      File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{key_id}.p8"))
)
Spaceship::ConnectAPI.token = token

# **tunes 클라이언트를 손으로 만든다.** `ConnectAPI.token=` 은 공개 API
# 클라이언트만 세운다. 그대로 두면 dataUsages 요청이 api.appstoreconnect
# 으로 가서 "The relationship 'dataUsages' does not exist" 로 되돌아온다.
Spaceship::ConnectAPI::Tunes::Client.new(token: token)

existing = Spaceship::ConnectAPI::AppDataUsage.all(
  app_id: APP_ID, includes: 'category,grouping,purpose,dataProtection', limit: 500
)
puts "기존 신고 항목: #{existing.size}개 — 지우고 새로 쓴다"
existing.each(&:delete!)

USAGES.each do |u|
  u[:purposes].each do |purpose|
    Spaceship::ConnectAPI::AppDataUsage.create(
      app_id: APP_ID,
      app_data_usage_category_id: u[:category],
      app_data_usage_purpose_id: purpose,
      app_data_usage_protection_id: u[:protection]
    )
    puts "  + #{u[:category]} · #{purpose} · #{u[:protection]}"
  end
end

state = Spaceship::ConnectAPI.get_app_data_usages_publish_state(app_id: APP_ID).to_models.first
puts "게시 상태: #{state.published}"
unless state.published
  Spaceship::ConnectAPI.patch_app_data_usages_publish_state(
    app_data_usages_publish_state_id: state.id, published: true
  )
  after = Spaceship::ConnectAPI.get_app_data_usages_publish_state(app_id: APP_ID).to_models.first
  puts "게시함 → #{after.published}"
end
