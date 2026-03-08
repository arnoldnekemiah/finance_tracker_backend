module AdminAuthenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_admin_user
  end

  private

  def current_admin_user
    return @current_admin_user if defined?(@current_admin_user)

    @current_admin_user = admin_from_session || admin_from_jwt
  end

  def admin_from_session
    return nil unless session[:admin_user_id]
    user = User.find_by(id: session[:admin_user_id])
    user&.admin? ? user : nil
  end

  def admin_from_jwt
    token = request.headers['Authorization']&.split(' ')&.last
    return nil unless token

    payload = JwtService.decode(token)
    return nil unless payload&.dig('user_id')

    user = User.find_by(id: payload['user_id'])
    user&.admin? ? user : nil
  end

  def authenticate_admin_user!
    unless current_admin_user
      respond_to do |format|
        format.html { redirect_to admin_login_path, alert: 'Please log in to access the admin panel' }
        format.json { render json: { error: 'Admin authentication required' }, status: :unauthorized }
      end
    end
  end

  def log_admin_action(action, resource: nil, details: nil)
    return unless current_admin_user
    AdminAuditLog.log(
      user: current_admin_user,
      action: action,
      resource: resource,
      details: details,
      request: request
    )
  end
end
