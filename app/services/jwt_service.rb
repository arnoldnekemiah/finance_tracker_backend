class JwtService
  SECRET = Rails.application.credentials.jwt_secret_key || ENV['JWT_SECRET_KEY'] || 'fallback_dev_secret'

  def self.encode(user_id, jti: SecureRandom.uuid, exp: 24.hours.from_now)
    payload = { user_id: user_id, jti: jti, exp: exp.to_i }
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: 'HS256')
    decoded[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
