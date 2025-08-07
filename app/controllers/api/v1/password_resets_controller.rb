class Api::V1::PasswordResetsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, only: [:create, :update]
  before_action :find_user_by_token, only: [:update]

  # POST /api/v1/password_reset
  def create
    user = User.find_by(email: params[:email])
    
    if user
      # Generate password reset token
      reset_token = generate_reset_token
      user.update!(
        reset_password_token: Digest::SHA256.hexdigest(reset_token),
        reset_password_sent_at: Time.current
      )
      
      # In production, send email with reset_token
      # For now, return success message
      render json: {
        message: 'If an account with that email exists, password reset instructions have been sent.',
        # Remove this line in production for security
        reset_token: reset_token
      }, status: :ok
    else
      # Always return success to prevent email enumeration
      render json: {
        message: 'If an account with that email exists, password reset instructions have been sent.'
      }, status: :ok
    end
  end

  # PATCH /api/v1/password_reset
  def update
    if @user && valid_reset_token?
      if @user.update(password_params)
        # Clear reset token
        @user.update!(
          reset_password_token: nil,
          reset_password_sent_at: nil
        )
        
        render json: {
          message: 'Password has been successfully reset. You can now log in with your new password.'
        }, status: :ok
      else
        render json: {
          errors: @user.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: {
        error: 'Invalid or expired reset token'
      }, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_token
    return unless params[:reset_token].present?
    
    hashed_token = Digest::SHA256.hexdigest(params[:reset_token])
    @user = User.find_by(reset_password_token: hashed_token)
  end

  def valid_reset_token?
    return false unless @user&.reset_password_sent_at
    
    # Token expires after 2 hours
    @user.reset_password_sent_at > 2.hours.ago
  end

  def generate_reset_token
    SecureRandom.urlsafe_base64(32)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
