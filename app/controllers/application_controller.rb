class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    user_not_authorized
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    not_found
  end

  private
  
  def current_user
    @current_user ||= super || User.find_by(id: session[:user_id])
  end
  
  def authenticate_user!(_options = {})
    head :unauthorized unless signed_in?
  end
  
  def signed_in?
    current_user.present?
  end

  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password, :password_confirmation, :currency])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :email, :password, :password_confirmation, :current_password, :currency])
  end

  def user_not_authorized
    render json: { error: 'You are not authorized to perform this action.' }, status: :unauthorized
  end

  def not_found
    render json: { error: 'Resource not found' }, status: :not_found
  end
end
