module AuthHelpers
  def auth_token(user)
    JwtService.encode(user.id, jti: user.jti)
  end

  def auth_headers(user)
    { 'Authorization' => "Bearer #{auth_token(user)}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
