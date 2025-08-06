class Admin::DashboardController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!
  before_action :ensure_admin_access
  
  rescue_from StandardError, with: :handle_dashboard_error
  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  def index
    authorize! :manage, :admin_dashboard
    
    begin
      @stats = system_statistics
      @user_metrics = user_metrics
      @financial_metrics = financial_metrics
      @recent_activity = recent_activity
      @health = system_health
      
      # Admin dashboard only supports HTML views
      render :index
    rescue => e
      handle_dashboard_error(e)
    end
  end

  def health_metrics
    authorize! :manage, :admin_dashboard
    
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

  def ensure_admin_access
    unless current_user&.admin?
      respond_to do |format|
        format.html { redirect_to admin_login_path, alert: 'Admin access required' }
        format.json { render json: { error: 'Admin access required' }, status: :forbidden }
      end
    end
  end

  def system_statistics
    {
      total_users: User.count,
      admin_users: User.admins.count,
      active_users_today: UserAnalytics.where(
        event_type: 'login',
        created_at: Date.current.beginning_of_day..Date.current.end_of_day
      ).distinct.count(:user_id),
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
    UserAnalytics.user_growth_metrics(30.days.ago, Time.current)
  end

  def financial_metrics
    UserAnalytics.transaction_volume_metrics(30.days.ago, Time.current)
  end

  def recent_activity
    UserAnalytics.includes(:user)
                 .recent
                 .limit(20)
                 .map do |activity|
      {
        id: activity.id,
        user: {
          id: activity.user.id,
          name: activity.user.full_name,
          email: activity.user.email
        },
        event_type: activity.event_type,
        event_data: activity.event_data,
        created_at: activity.created_at
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
    {
      status: 'unhealthy',
      error: e.message
    }
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
      average_response_time: '< 100ms', # This would be calculated from logs in production
      requests_per_minute: 0, # This would be calculated from logs in production
      error_rate: '< 1%' # This would be calculated from logs in production
    }
  end
  
  # Error handling methods
  def handle_dashboard_error(exception)
    Rails.logger.error "Dashboard Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    flash[:alert] = "Unable to load dashboard data. Please refresh the page or try again later."
    
    # Set safe default values for dashboard
    @stats = { total_users: 0, admin_users: 0, active_users_today: 0, new_users_today: 0, total_transactions: 0, transactions_today: 0 }
    @user_metrics = { total_users: 0, new_users_period: 0, active_users_period: 0, registrations_by_day: {} }
    @financial_metrics = { total_transactions: 0, transactions_period: 0, transaction_volume: 0, transactions_by_day: {}, avg_transaction_amount: 0 }
    @recent_activity = []
    @health = { rails_env: Rails.env, ruby_version: RUBY_VERSION, rails_version: Rails.version, uptime: 'Unknown', memory_usage: 0 }
    
    render :index
  end
  
  def handle_access_denied(exception)
    flash[:alert] = "You don't have permission to access the admin dashboard."
    redirect_to admin_login_path
  end
end
