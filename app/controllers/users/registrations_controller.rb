class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionsFix
  
  skip_before_action :verify_authenticity_token
  
  respond_to :json

  before_action :configure_sign_up_params, only: [:create]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :currency])
  end

  private

  def respond_with(current_user, _opts = {})
    if resource.persisted?
      render json: {
        status: {code: 200, message: 'Signed up successfully.'},
        data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
      }
    else
      render json: {
        status: {message: "User couldn't be created successfully. #{current_user.errors.full_messages.to_sentence}"}
      }, status: :unprocessable_entity
    end
  end
end
