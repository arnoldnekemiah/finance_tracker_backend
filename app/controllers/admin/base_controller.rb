class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_access

  private

  def ensure_admin_access
    unless current_user&.admin?
      render json: { 
        error: 'Admin access required',
        message: 'You must be an administrator to access this resource'
      }, status: :forbidden
    end
  end

  def authorize_admin_action!(action, resource = nil)
    authorize! action, resource || :admin_panel
  rescue CanCan::AccessDenied
    render json: { 
      error: 'Insufficient permissions',
      message: 'You do not have permission to perform this action'
    }, status: :forbidden
  end
end
