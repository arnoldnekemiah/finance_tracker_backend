class Admin::AuditLogsController < Admin::BaseController
  def index
    @audit_logs = AdminAuditLog.includes(:user).recent

    @audit_logs = @audit_logs.by_action(params[:action_filter]) if params[:action_filter].present?
    @audit_logs = @audit_logs.by_admin(params[:admin_id]) if params[:admin_id].present?

    if params[:start_date].present?
      @audit_logs = @audit_logs.where('created_at >= ?', Date.parse(params[:start_date]).beginning_of_day)
    end
    if params[:end_date].present?
      @audit_logs = @audit_logs.where('created_at <= ?', Date.parse(params[:end_date]).end_of_day)
    end

    @audit_logs = @audit_logs.page(params[:page]).per(params[:per_page] || 25)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          audit_logs: @audit_logs.map { |log| audit_log_json(log) },
          pagination: {
            current_page: @audit_logs.current_page,
            total_pages: @audit_logs.total_pages,
            total_count: @audit_logs.total_count
          }
        }
      }
      format.csv {
        send_data export_csv(@audit_logs),
          filename: "audit_logs_#{Date.current}.csv",
          type: 'text/csv'
      }
    end
  end

  private

  def audit_log_json(log)
    {
      id: log.id,
      admin: log.user&.full_name,
      admin_email: log.user&.email,
      action: log.action,
      resource_type: log.resource_type,
      resource_id: log.resource_id,
      details: log.details,
      ip_address: log.ip_address,
      created_at: log.created_at
    }
  end

  def export_csv(logs)
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Admin', 'Email', 'Action', 'Resource', 'Details', 'IP Address', 'Timestamp']
      logs.each do |log|
        csv << [
          log.id, log.user&.full_name, log.user&.email, log.action,
          "#{log.resource_type}##{log.resource_id}", log.details,
          log.ip_address, log.created_at
        ]
      end
    end
  end
end
