class Admin::DashboardController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!
  before_action :ensure_admin_access

  def index
    authorize! :manage, :admin_dashboard
    
    @stats = system_statistics
    @user_metrics = user_metrics
    @financial_metrics = financial_metrics
    @recent_activity = recent_activity
    @health = system_health
    
    respond_to do |format|
      format.html # Render the view
      format.json {
        render json: {
          system_stats: @stats,
          user_metrics: @user_metrics,
          financial_metrics: @financial_metrics,
          recent_activity: @recent_activity
        }
      }
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
end
