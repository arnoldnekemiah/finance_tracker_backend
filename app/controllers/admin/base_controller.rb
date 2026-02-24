class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_access

  private

  def ensure_admin_access
    unless current_user&.admin?
      respond_to do |format|
        format.html { redirect_to admin_login_path, alert: 'Admin access required' }
        format.json { render json: { error: 'Admin access required' }, status: :forbidden }
      end
    end
  end
end
