class Admin::AnalyticsController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!
  before_action :ensure_admin_access
  
  rescue_from StandardError, with: :handle_error
  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  def index
    authorize! :manage, :analytics
    # Main analytics dashboard view
  end

  def user_growth
    authorize! :manage, :analytics
    
    begin
      start_date = parse_date(params[:start_date]) || 30.days.ago
      end_date = parse_date(params[:end_date]) || Time.current
      
      @metrics = UserAnalytics.user_growth_metrics(start_date, end_date)
      @start_date = start_date
      @end_date = end_date
      
      # Admin analytics only supports HTML views
      render :user_growth
    rescue => e
      handle_analytics_error(e, 'user growth')
    end
  end

  def transaction_volume
    authorize! :manage, :analytics
    
    begin
      start_date = parse_date(params[:start_date]) || 30.days.ago
      end_date = parse_date(params[:end_date]) || Time.current
      
      @metrics = UserAnalytics.transaction_volume_metrics(start_date, end_date)
      @start_date = start_date
      @end_date = end_date
      
      # Admin analytics only supports HTML views
      render :transaction_volume
    rescue => e
      handle_analytics_error(e, 'transaction volume')
    end
  end

  def financial_insights
    authorize! :manage, :analytics
    
    begin
      start_date = parse_date(params[:start_date]) || 30.days.ago
      end_date = parse_date(params[:end_date]) || Time.current
      
      @insights = UserAnalytics.financial_insights(start_date, end_date)
      @start_date = start_date
      @end_date = end_date
      
      # Admin analytics only supports HTML views
      render :financial_insights
    rescue => e
      handle_analytics_error(e, 'financial insights')
    end
  end

  def user_activity
    authorize! :manage, :analytics
    
    activities = UserAnalytics.includes(:user)
                             .where(created_at: date_range)
                             .group(:event_type)
                             .count

    activity_by_day = UserAnalytics.where(created_at: date_range)
                                  .group("DATE(created_at)")
                                  .group(:event_type)
                                  .count

    @activities = activities
    @activity_by_day = activity_by_day
    @top_active_users = top_active_users
    @recent_activities = recent_activities
    
    # Admin analytics only supports HTML views
    render :user_activity
  end

  def revenue_analytics
    authorize! :manage, :analytics
    
    begin
      # This would be more relevant if you had subscription or premium features
      @revenue_data = {
        total_users: User.count,
        premium_users: 0, # Placeholder for premium feature
        monthly_recurring_revenue: 0, # Placeholder
        user_lifetime_value: calculate_user_lifetime_value,
        churn_rate: calculate_churn_rate
      }
      
      # Admin analytics only supports HTML views
      render :revenue_analytics
    rescue => e
      handle_analytics_error(e, 'revenue analytics')
    end
  end

  def export_data
    authorize! :manage, :reports
    
    format = params[:format] || 'csv'
    data_type = params[:data_type] || 'users'
    
    case data_type
    when 'users'
      data = export_users_data(format)
    when 'transactions'
      data = export_transactions_data(format)
    when 'analytics'
      data = export_analytics_data(format)
    else
      render json: { error: 'Invalid data type' }, status: :bad_request
      return
    end

    send_data data[:content], 
              filename: data[:filename], 
              type: data[:content_type]
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

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end

  def date_range
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date = parse_date(params[:end_date]) || Time.current
    start_date..end_date
  end

  def top_active_users
    UserAnalytics.joins(:user)
                 .where(created_at: date_range)
                 .group(:user_id)
                 .count
                 .sort_by { |_, count| -count }
                 .first(10)
                 .map do |user_id, activity_count|
      user = User.find(user_id)
      {
        user: {
          id: user.id,
          name: user.full_name,
          email: user.email
        },
        activity_count: activity_count
      }
    end
  end

  def recent_activities
    UserAnalytics.includes(:user)
                 .where(created_at: date_range)
                 .recent
                 .limit(50)
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

  def calculate_user_lifetime_value
    # Simple calculation based on user activity
    avg_transactions_per_user = Transaction.count.to_f / User.count
    avg_transaction_value = Transaction.average(:amount) || 0
    avg_transactions_per_user * avg_transaction_value.abs
  end

  def calculate_churn_rate
    # Simple churn calculation - users who haven't logged in in 30 days
    total_users = User.count
    return 0 if total_users == 0
    
    inactive_users = User.left_joins(:user_analytics)
                         .where(user_analytics: { event_type: 'login' })
                         .where('user_analytics.created_at < ?', 30.days.ago)
                         .or(User.left_joins(:user_analytics).where(user_analytics: { id: nil }))
                         .distinct
                         .count
    
    (inactive_users.to_f / total_users * 100).round(2)
  end

  def export_users_data(format)
    users = User.includes(:transactions, :budgets, :accounts)
    
    case format
    when 'csv'
      require 'csv'
      csv_data = CSV.generate(headers: true) do |csv|
        csv << ['ID', 'Email', 'Full Name', 'Admin', 'Created At', 'Transactions Count', 'Total Transaction Amount']
        users.each do |user|
          csv << [
            user.id,
            user.email,
            user.full_name,
            user.admin?,
            user.created_at,
            user.transactions.count,
            user.transactions.sum(:amount)
          ]
        end
      end
      {
        content: csv_data,
        filename: "users_export_#{Date.current}.csv",
        content_type: 'text/csv'
      }
    when 'json'
      {
        content: users.map { |u| user_export_data(u) }.to_json,
        filename: "users_export_#{Date.current}.json",
        content_type: 'application/json'
      }
    end
  end

  def export_transactions_data(format)
    transactions = Transaction.includes(:user, :category, :account)
    
    case format
    when 'csv'
      require 'csv'
      csv_data = CSV.generate(headers: true) do |csv|
        csv << ['ID', 'User Email', 'Amount', 'Description', 'Category', 'Account', 'Date', 'Created At']
        transactions.each do |transaction|
          csv << [
            transaction.id,
            transaction.user.email,
            transaction.amount,
            transaction.description,
            transaction.category&.name,
            transaction.account&.name,
            transaction.date,
            transaction.created_at
          ]
        end
      end
      {
        content: csv_data,
        filename: "transactions_export_#{Date.current}.csv",
        content_type: 'text/csv'
      }
    end
  end

  def export_analytics_data(format)
    analytics = UserAnalytics.includes(:user).where(created_at: date_range)
    
    case format
    when 'csv'
      require 'csv'
      csv_data = CSV.generate(headers: true) do |csv|
        csv << ['ID', 'User Email', 'Event Type', 'Event Data', 'IP Address', 'Created At']
        analytics.each do |analytic|
          csv << [
            analytic.id,
            analytic.user.email,
            analytic.event_type,
            analytic.event_data.to_json,
            analytic.ip_address,
            analytic.created_at
          ]
        end
      end
      {
        content: csv_data,
        filename: "analytics_export_#{Date.current}.csv",
        content_type: 'text/csv'
      }
    end
  end

  def user_export_data(user)
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      admin: user.admin?,
      created_at: user.created_at,
      transactions_count: user.transactions.count,
      total_transaction_amount: user.transactions.sum(:amount),
      accounts_count: user.accounts.count,
      budgets_count: user.budgets.count
    }
  end
  
  # Error handling methods
  def handle_error(exception)
    Rails.logger.error "Analytics Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    flash[:alert] = "An error occurred while loading analytics data. Please try again."
    redirect_to admin_analytics_path
  end
  
  def handle_access_denied(exception)
    flash[:alert] = "You don't have permission to access this analytics feature."
    redirect_to admin_root_path
  end
  
  def handle_analytics_error(exception, feature_name)
    Rails.logger.error "Analytics #{feature_name} Error: #{exception.message}"
    
    flash[:alert] = "Unable to load #{feature_name} data. Please try again later."
    redirect_to admin_analytics_path
  end
end
