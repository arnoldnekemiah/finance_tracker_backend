class Admin::PasswordResetsController < ApplicationController
  before_action :authenticate_user!, except: [:create, :update]
  before_action :find_user_by_token, only: [:update]

  def create
    user = User.find_by(email: params[:email])

    if user&.admin?
      reset_token = SecureRandom.urlsafe_base64(32)
      user.update!(
        reset_password_token: Digest::SHA256.hexdigest(reset_token),
        reset_password_sent_at: Time.current
      )

      render json: {
        message: 'Password reset instructions sent',
        reset_token: reset_token
      }
    else
      render json: { error: 'Admin account not found' }, status: :not_found
    end
  end

  def update
    if @user && valid_reset_token?
      if @user.update(password_params)
        @user.update!(reset_password_token: nil, reset_password_sent_at: nil)
        render json: { message: 'Password updated successfully' }
      else
        render json: { error: @user.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Invalid or expired reset token' }, status: :unauthorized
    end
  end

  def change_password
    if current_user.valid_password?(params[:current_password])
      if current_user.update(password_params)
        render json: { message: 'Password changed successfully' }
      else
        render json: { error: current_user.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Current password is incorrect' }, status: :unauthorized
    end
  end

  private

  def find_user_by_token
    return unless params[:reset_token].present?
    hashed_token = Digest::SHA256.hexdigest(params[:reset_token])
    @user = User.find_by(reset_password_token: hashed_token)
  end

  def valid_reset_token?
    @user&.reset_password_sent_at && @user.reset_password_sent_at > 2.hours.ago
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
