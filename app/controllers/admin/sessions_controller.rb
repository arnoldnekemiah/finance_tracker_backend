class Admin::SessionsController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!, only: [:new, :create]
  protect_from_forgery with: :exception, except: [:create]

  def new
    # Show login form
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password]) && user.admin?
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
            user: {
              id: user.id,
              email: user.email,
              full_name: user.full_name,
              is_admin: user.admin?
            }
          }, status: :ok
        }
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:alert] = 'Invalid admin credentials'
          render :new, status: :unauthorized
        }
        format.json {
          render json: { error: 'Invalid admin credentials' }, status: :unauthorized
        }
      end
    end
  end

  def destroy
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
    render json: {
      valid: true,
      user: {
        id: current_user.id,
        email: current_user.email,
        full_name: current_user.full_name,
        is_admin: current_user.admin?
      }
    }
  end
end
