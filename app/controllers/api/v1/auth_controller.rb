class Api::V1::AuthController < Api::BaseController
  include Authenticatable

  skip_before_action :authenticate_user!, only: [:signup, :login, :google, :forgot_password, :verify_otp, :reset_password]

  # POST /api/v1/auth/signup
  def signup
    user = User.new(signup_params)
    user.provider = 'email'
    user.jti = SecureRandom.uuid

    if user.save
      token = JwtService.encode(user.id, jti: user.jti)
      render json: {
        status: 'success',
        data: {
          user: user_json(user),
          token: token
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        error: user.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/auth/login
  def login
    user = User.find_by(email: params[:email]&.downcase)

    if user&.valid_password?(params[:password])
      unless user.is_active
        return render json: {
          status: 'error',
          error: 'Account is deactivated. Please contact support.'
        }, status: :unauthorized
      end

      token = JwtService.encode(user.id, jti: user.jti)
      render json: {
        status: 'success',
        data: {
          user: user_json(user),
          token: token
        }
      }
    else
      render json: {
        status: 'error',
        error: 'Invalid email or password'
      }, status: :unauthorized
    end
  end

  # POST /api/v1/auth/google
  def google
    begin
      user = User.from_google(
        email: params[:email],
        first_name: params[:first_name],
        last_name: params[:last_name],
        uid: params[:uid],
        photo_url: params[:photo_url]
      )

      token = JwtService.encode(user.id, jti: user.jti)
      render json: {
        status: 'success',
        data: {
          user: user_json(user),
          token: token
        }
      }
    rescue => e
      render json: {
        status: 'error',
        error: "Google authentication failed: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/auth/logout
  def logout
    # Rotate the JTI so any existing tokens for this user become invalid.
    # The JTIMatcher revocation strategy checks jti on every request, so any
    # token carrying the old jti will be rejected after this.
    current_user.update_column(:jti, SecureRandom.uuid)
    render json: {
      status: 'success',
      data: { message: 'Logged out successfully' }
    }
  end

  # GET /api/v1/auth/me
  def me
    render json: {
      status: 'success',
      data: user_json(current_user)
    }
  end

  # POST /api/v1/auth/forgot_password
  def forgot_password
    user = User.find_by(email: params[:email]&.downcase)

    if user
      user.generate_reset_otp!
      UserMailer.reset_password_otp(user).deliver_later
    end

    # Always return success to prevent email enumeration
    render json: {
      status: 'success',
      data: { message: 'If an account with that email exists, a password reset code has been sent.' }
    }
  end

  # POST /api/v1/auth/verify_otp
  def verify_otp
    user = User.find_by(email: params[:email]&.downcase)

    if user&.verify_reset_otp(params[:otp])
      temp_token = JwtService.encode(user.id, exp: 15.minutes.from_now)
      render json: {
        status: 'success',
        data: {
          message: 'OTP verified successfully',
          reset_token: temp_token
        }
      }
    else
      render json: {
        status: 'error',
        error: 'Invalid or expired OTP'
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/auth/reset_password
  def reset_password
    payload = JwtService.decode(params[:token])

    if payload && payload['user_id']
      user = User.find_by(id: payload['user_id'])

      if user && user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        user.clear_reset_otp!
        render json: {
          status: 'success',
          data: { message: 'Password has been reset successfully' }
        }
      else
        render json: {
          status: 'error',
          error: user&.errors&.full_messages&.join(', ') || 'Failed to reset password'
        }, status: :unprocessable_entity
      end
    else
      render json: {
        status: 'error',
        error: 'Invalid or expired reset token'
      }, status: :unprocessable_entity
    end
  end

  private

  def signup_params
    params.permit(:email, :password, :password_confirmation, :first_name, :last_name, :currency)
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      currency: user.currency,
      preferred_currency: user.preferred_currency,
      timezone: user.timezone,
      photo_url: user.photo_url,
      is_admin: user.is_admin,
      is_active: user.is_active,
      provider: user.provider,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
