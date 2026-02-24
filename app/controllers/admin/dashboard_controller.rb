class Admin::DashboardController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!

  rescue_from StandardError, with: :handle_dashboard_error

  def index
    begin
      @stats = system_statistics
      @user_metrics = user_metrics
      @financial_metrics = financial_metrics
      @recent_activity = recent_activity
      @health = system_health
      render :index
    rescue => e
      handle_dashboard_error(e)
    end
  end

  def health_metrics
    render json: {
      database_status: database_health,
      system_health: system_health,
      performance_metrics: performance_metrics
    }
  end

  private

  def authenticate_admin_user!
    unless current_user&.admin?
      redirect_to admin_login_path, alert: 'Please log in as an administrator'
    end
  end

  def system_statistics
    {
      total_users: User.count,
      admin_users: User.admins.count,
      active_users_today: User.where(
        updated_at: Date.current.beginning_of_day..Date.current.end_of_day
      ).count,
      new_registrations_today: User.where(
        created_at: Date.current.beginning_of_day..Date.current.end_of_day
      ).count,
      total_transactions: Transaction.count,
      transactions_today: Transaction.where(
        created_at: Date.current.beginning_of_day..Date.current.end_of_day
      ).count
    }
  end

  def user_metrics
    registrations = User.where('created_at >= ?', 30.days.ago)
                       .group("DATE(created_at)")
                       .count
    { registrations_by_day: registrations }
  end

  def financial_metrics
    transactions = Transaction.where('created_at >= ?', 30.days.ago)
                             .group("DATE(created_at)")
                             .count
    { transactions_by_day: transactions }
  end

  def recent_activity
    User.order(updated_at: :desc).limit(10).map do |user|
      {
        user: { id: user.id, name: user.full_name, email: user.email },
        event_type: 'activity',
        created_at: user.updated_at
      }
    end
  end

  def database_health
    {
      status: 'healthy',
      connection_pool: ActiveRecord::Base.connection_pool.stat,
      tables_count: ActiveRecord::Base.connection.tables.count
    }
  rescue => e
    { status: 'unhealthy', error: e.message }
  end

  def system_health
    {
      rails_env: Rails.env,
      ruby_version: RUBY_VERSION,
      rails_version: Rails.version,
      uptime: 'Running',
      memory_usage: `ps -o rss= -p #{Process.pid}`.to_i
    }
  end

  def performance_metrics
    {
      average_response_time: '< 100ms',
      requests_per_minute: 0,
      error_rate: '< 1%'
    }
  end

  def handle_dashboard_error(exception)
    Rails.logger.error "Dashboard Error: #{exception.message}"
    flash[:alert] = "Unable to load dashboard data."

    @stats = { total_users: 0, admin_users: 0, active_users_today: 0, new_registrations_today: 0, total_transactions: 0, transactions_today: 0 }
    @user_metrics = { registrations_by_day: {} }
    @financial_metrics = { transactions_by_day: {} }
    @recent_activity = []
    @health = { rails_env: Rails.env, ruby_version: RUBY_VERSION, rails_version: Rails.version, uptime: 'Unknown', memory_usage: 0 }

    render :index
  end
end
