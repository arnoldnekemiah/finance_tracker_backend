class Admin::SettingsController < Admin::BaseController
  def index
    @admin_users = User.admins.order(:email)
    @platform_stats = {
      total_users: User.count,
      total_admins: User.admins.count,
      pending_invitations: AdminInvitation.pending.count,
      audit_logs_count: AdminAuditLog.count
    }

    respond_to do |format|
      format.html
      format.json { render json: @platform_stats }
    end
  end
end
