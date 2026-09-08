# 앱 개인정보(데이터 수집 신고)를 "수집하지 않음"으로 게시한다.
#
# **공개 App Store Connect API 에는 이 자리가 없다.** /v1/appDataUsages 는
# PATH_ERROR 로 답하고, 앱 리소스의 관계 목록에도 안 들어 있다. 실제 자리는
# 콘솔이 쓰는 iris API 이고, spaceship 의 tunes 클라이언트가 그리로 간다.
#
#   ruby tool/app_privacy.rb
require 'spaceship'

APP_ID = '6757940370'

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

usages = Spaceship::ConnectAPI::AppDataUsage.all(
  app_id: APP_ID, includes: 'category,grouping,dataProtection'
)
puts "기존 신고 항목: #{usages.size}개"
usages.each { |u| puts "  - #{u.category&.id || '(없음)'} / #{u.data_protection&.id}" }

unless usages.any?(&:is_not_collected?)
  # 카테고리 없이 dataProtection 만 준다 — 그것이 "수집하지 않음" 한 줄이다.
  Spaceship::ConnectAPI::AppDataUsage.create(
    app_id: APP_ID,
    app_data_usage_protection_id: Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_NOT_COLLECTED
  )
  puts '"데이터를 수집하지 않음" 추가'
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
