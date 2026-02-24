class ApplicationController < ActionController::Base
  include ActionController::Cookies
  include Authenticatable

  protect_from_forgery with: :null_session

  respond_to :json, :html

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    render json: { status: 'error', error: 'Resource not found' }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render json: { status: 'error', error: exception.message }, status: :unprocessable_entity
  end
end
