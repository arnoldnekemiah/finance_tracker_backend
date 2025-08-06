class Admin::PasswordResetsController < ApplicationController
  before_action :authenticate_user!, except: [:create, :update]
  before_action :ensure_admin_access, except: [:create, :update]
  before_action :find_user_by_token, only: [:update]

  def create
    user = User.find_by(email: params[:email])
    
    if user&.admin?
      # Generate password reset token
      reset_token = generate_reset_token
      user.update!(
        reset_password_token: Digest::SHA256.hexdigest(reset_token),
        reset_password_sent_at: Time.current
      )
      
      # In a real application, you would send this via email
      # For now, we'll return it in the response (not recommended for production)
      render json: {
        message: 'Password reset instructions sent',
        reset_token: reset_token, # Remove this in production
        instructions: 'Use the reset token to set a new password'
      }
      
      UserAnalytics.track_event(
        user,
        'admin_password_reset_requested',
        {
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        }
      )
    else
      render json: {
        error: 'Admin account not found'
      }, status: :not_found
    end
  end

  def update
    if @user && valid_reset_token?
      if @user.update(password_params)
        # Clear reset token
        @user.update!(
          reset_password_token: nil,
          reset_password_sent_at: nil
        )
        
        UserAnalytics.track_event(
          @user,
          'admin_password_reset_completed',
          {
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          }
        )
        
        render json: {
          message: 'Password updated successfully'
        }
      else
        render json: {
          error: 'Failed to update password',
          errors: @user.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: {
        error: 'Invalid or expired reset token'
      }, status: :unauthorized
    end
  end

  def change_password
    authorize! :manage, :admin_panel
    
    if current_user.valid_password?(params[:current_password])
      if current_user.update(password_params)
        UserAnalytics.track_event(
          current_user,
          'admin_password_changed',
          {
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          }
        )
        
        render json: {
          message: 'Password changed successfully'
        }
      else
        render json: {
          error: 'Failed to change password',
          errors: current_user.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: {
        error: 'Current password is incorrect'
      }, status: :unauthorized
    end
  end

  private

  def ensure_admin_access
    unless current_user&.admin?
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end

  def find_user_by_token
    return unless params[:reset_token].present?
    
    hashed_token = Digest::SHA256.hexdigest(params[:reset_token])
    @user = User.find_by(reset_password_token: hashed_token)
  end

  def valid_reset_token?
    @user&.reset_password_sent_at && 
    @user.reset_password_sent_at > 2.hours.ago
  end

  def generate_reset_token
    SecureRandom.urlsafe_base64(32)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
