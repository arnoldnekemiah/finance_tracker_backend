class Users::SessionsController < Devise::SessionsController
  include RackSessionsFix

  respond_to :json

  private
  def respond_with(current_user, _opts = {})
    render json: {
      status: { 
        code: 200, message: 'Logged in successfully.',
        data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
      }
    }, status: :ok
  end
  def respond_to_on_destroy
    begin
      if request.headers['Authorization'].present?
        jwt_payload = JWT.decode(
          request.headers['Authorization'].split(' ').last,
          Rails.application.credentials.devise_jwt_secret_key!,
          true,
          algorithm: 'HS256'
        ).first

        current_user = User.find(jwt_payload['sub'])
        
        render json: {
          status: 200,
          message: 'Logged out successfully.'
        }, status: :ok
      else
        render json: {
          status: 401,
          message: 'No active session found.'
        }, status: :unauthorized
      end
    rescue JWT::DecodeError
      render json: {
        status: 401,
        message: 'Invalid token.'
      }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: 401,
        message: 'User not found.'
      }, status: :unauthorized
    rescue => e
      render json: {
        status: 500,
        message: 'An error occurred during logout.'
      }, status: :internal_server_error
    end
  end
 
end
