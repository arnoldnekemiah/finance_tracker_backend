class Admin::SessionsController < ApplicationController
  include AdminAuthenticatable

  layout 'admin'
  skip_before_action :authenticate_user!
  protect_from_forgery with: :exception, except: [:create]

  def new
    redirect_to admin_root_path if current_admin_user
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.valid_password?(params[:password]) && user.admin?
      unless user.active?
        return login_failure('Account is deactivated. Please contact support.')
      end

      user.record_admin_login!
      AdminAuditLog.log(user: user, action: 'admin_login', request: request)
      AdminMailer.admin_session_alert(user, request.remote_ip, request.user_agent || '').deliver_later

      respond_to do |format|
        format.html {
          session[:admin_user_id] = user.id
          redirect_to admin_root_path, notice: 'Successfully logged in!'
        }
        format.json {
          token = JwtService.encode(user.id)
          render json: {
            message: 'Admin logged in successfully',
            token: token,
            user: admin_user_json(user)
          }, status: :ok
        }
      end
    else
      login_failure('Invalid admin credentials')
    end
  end

  def destroy
    log_admin_action('admin_logout') if current_admin_user
    respond_to do |format|
      format.html {
        session[:admin_user_id] = nil
        redirect_to admin_login_path, notice: 'Successfully logged out!'
      }
      format.json {
        render json: { message: 'Admin logged out successfully' }, status: :ok
      }
    end
  end

  def validate_token
    if current_admin_user
      render json: { valid: true, user: admin_user_json(current_admin_user) }
    else
      render json: { valid: false }, status: :unauthorized
    end
  end

  # Admin forgot password (OTP-based)
  def forgot_password
    # Render form for HTML, handle POST for JSON
  end

  def send_reset_otp
    user = User.find_by(email: params[:email]&.downcase)

    if user&.admin?
      begin
        user.generate_reset_otp!
        AdminMailer.admin_password_reset_otp(user).deliver_later
      rescue StandardError => e
        return render json: { error: e.message }, status: :too_many_requests if e.message.include?('Too many OTP')
      end
    end

    respond_to do |format|
      format.html {
        flash[:notice] = 'If an admin account exists, a reset code has been sent.'
        redirect_to admin_login_path
      }
      format.json {
        render json: { message: 'If an admin account exists, a reset code has been sent.' }
      }
    end
  end

  def verify_reset_otp
    user = User.find_by(email: params[:email]&.downcase)

    if user&.admin? && user.verify_reset_otp(params[:otp])
      temp_token = JwtService.encode(user.id, exp: 15.minutes.from_now)
      respond_to do |format|
        format.html {
          session[:reset_token] = temp_token
          redirect_to admin_reset_password_path
        }
        format.json {
          render json: { message: 'OTP verified', reset_token: temp_token }
        }
      end
    else
      respond_to do |format|
        format.html {
          flash[:alert] = 'Invalid or expired OTP'
          redirect_to admin_login_path
        }
        format.json {
          render json: { error: 'Invalid or expired OTP' }, status: :unprocessable_entity
        }
      end
    end
  end

  def reset_password
    token = params[:token] || session[:reset_token]
    payload = JwtService.decode(token)

    if payload && payload['user_id']
      user = User.find_by(id: payload['user_id'])
      if user&.admin? && user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        user.clear_reset_otp!
        AdminAuditLog.log(user: user, action: 'password_reset', request: request)
        session.delete(:reset_token)

        respond_to do |format|
          format.html { redirect_to admin_login_path, notice: 'Password reset successfully. Please log in.' }
          format.json { render json: { message: 'Password reset successfully' } }
        end
      else
        respond_to do |format|
          format.html {
            flash[:alert] = user&.errors&.full_messages&.join(', ') || 'Failed to reset password'
            redirect_to admin_login_path
          }
          format.json {
            render json: { error: user&.errors&.full_messages&.join(', ') || 'Failed to reset password' }, status: :unprocessable_entity
          }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_login_path, alert: 'Invalid or expired reset token' }
        format.json { render json: { error: 'Invalid or expired reset token' }, status: :unprocessable_entity }
      end
    end
  end

  private

  def login_failure(message)
    respond_to do |format|
      format.html {
        flash.now[:alert] = message
        render :new, status: :unauthorized
      }
      format.json {
        render json: { error: message }, status: :unauthorized
      }
    end
  end

  def admin_user_json(user)
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      first_name: user.first_name,
      last_name: user.last_name,
      is_admin: user.admin?,
      admin_role: user.admin_role,
      photo_url: user.photo_url,
      last_admin_login_at: user.last_admin_login_at
    }
  end
end
