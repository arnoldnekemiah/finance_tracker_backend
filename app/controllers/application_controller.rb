class ApplicationController < ActionController::Base
  include ActionController::Cookies
  protect_from_forgery with: :null_session
  
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  respond_to :json, :html

  rescue_from CanCan::AccessDenied do |exception|
    user_not_authorized
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    not_found
  end

  private
  
  def current_user
    @current_user ||= super || User.find_by(id: session[:user_id]) || admin_user_from_session
  end
  
  def admin_user_from_session
    return nil unless session[:admin_user_id]
    @admin_user ||= User.find_by(id: session[:admin_user_id], admin: true)
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
