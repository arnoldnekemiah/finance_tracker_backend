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
      # Track admin login
      UserAnalytics.track_event(
        user, 
        'admin_login', 
        {
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        }
      )
      
      respond_to do |format|
        format.html {
          session[:admin_user_id] = user.id
          redirect_to admin_root_path, notice: 'Successfully logged in!'
        }
        format.json {
          token = generate_jwt_token(user)
          render json: {
            message: 'Admin logged in successfully',
            token: token,
            user: {
              id: user.id,
              email: user.email,
              full_name: user.full_name,
              admin: user.admin?
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
          render json: { 
            error: 'Invalid admin credentials' 
          }, status: :unauthorized
        }
      end
    end
  end

  def destroy
    # Track admin logout
    if current_user
      UserAnalytics.track_event(
        current_user, 
        'admin_logout', 
        {
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        }
      )
    end
    
    respond_to do |format|
      format.html {
        session[:admin_user_id] = nil
        redirect_to admin_login_path, notice: 'Successfully logged out!'
      }
      format.json {
        render json: { 
          message: 'Admin logged out successfully' 
        }, status: :ok
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
        admin: current_user.admin?
      }
    }
  end

  private

  def authenticate_admin!
    authenticate_user!
    unless current_user&.admin?
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end

  def ensure_admin_access
    authorize! :access, :admin_panel
  end

  def generate_jwt_token(user)
    JWT.encode(
      {
        user_id: user.id,
        exp: 24.hours.from_now.to_i,
        admin: true
      },
      Rails.application.credentials.devise_jwt_secret_key
    )
  end
end
