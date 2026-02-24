module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last

    if token
      # Try custom JWT first
      payload = JwtService.decode(token)
      if payload && payload['user_id']
        @current_user = User.find_by(id: payload['user_id'])
        return if @current_user
      end

      # Try Devise JWT
      begin
        devise_secret = Rails.application.credentials.devise_jwt_secret_key
        if devise_secret
          decoded = JWT.decode(token, devise_secret, true, algorithm: 'HS256')
          user_id = decoded.first['sub']
          @current_user = User.find_by(id: user_id)
          return if @current_user
        end
      rescue JWT::DecodeError, JWT::ExpiredSignature
        # Fall through
      end
    end

    render json: { status: 'error', error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
