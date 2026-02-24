class Admin::AnalyticsController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!

  rescue_from StandardError, with: :handle_error

  def index
    # Main analytics dashboard view
  end

  def user_growth
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date = parse_date(params[:end_date]) || Time.current

    @metrics = {
      total_users: User.count,
      new_users_period: User.where(created_at: start_date..end_date).count,
      registrations_by_day: User.where(created_at: start_date..end_date).group("DATE(created_at)").count
    }
    @start_date = start_date
    @end_date = end_date
    render :user_growth
  rescue => e
    handle_analytics_error(e, 'user growth')
  end

  def transaction_volume
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date = parse_date(params[:end_date]) || Time.current

    @metrics = {
      total_transactions: Transaction.where(created_at: start_date..end_date).count,
      transactions_by_day: Transaction.where(created_at: start_date..end_date).group("DATE(created_at)").count,
      total_volume: Transaction.where(created_at: start_date..end_date).sum(:amount)
    }
    @start_date = start_date
    @end_date = end_date
    render :transaction_volume
  rescue => e
    handle_analytics_error(e, 'transaction volume')
  end

  def financial_insights
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date = parse_date(params[:end_date]) || Time.current

    @insights = {
      total_income: Transaction.income.where(date: start_date..end_date).sum(:amount),
      total_expenses: Transaction.expense.where(date: start_date..end_date).sum(:amount),
      avg_transaction: Transaction.where(created_at: start_date..end_date).average(:amount) || 0,
      top_categories: Transaction.expense.where(date: start_date..end_date)
                                .joins(:category).group('categories.name').sum(:amount)
                                .sort_by { |_, v| -v }.first(5)
    }
    @start_date = start_date
    @end_date = end_date
    render :financial_insights
  rescue => e
    handle_analytics_error(e, 'financial insights')
  end

  def user_activity
    @activities = User.where(updated_at: date_range).group("DATE(updated_at)").count
    @top_active_users = top_active_users
    @recent_activities = User.order(updated_at: :desc).limit(20).map do |u|
      { user: { id: u.id, name: u.full_name, email: u.email }, created_at: u.updated_at }
    end
    render :user_activity
  end

  def revenue_analytics
    @revenue_data = {
      total_users: User.count,
      active_users: User.active_users.count,
      user_lifetime_value: calculate_user_lifetime_value,
      churn_rate: calculate_churn_rate
    }
    render :revenue_analytics
  rescue => e
    handle_analytics_error(e, 'revenue analytics')
  end

  def export_data
    format = params[:format] || 'csv'
    data_type = params[:data_type] || 'users'

    case data_type
    when 'users' then data = export_users_data(format)
    when 'transactions' then data = export_transactions_data(format)
    else
      return render json: { error: 'Invalid data type' }, status: :bad_request
    end

    send_data data[:content], filename: data[:filename], type: data[:content_type]
  end

  private

  def authenticate_admin_user!
    unless current_user&.admin?
      redirect_to admin_login_path, alert: 'Admin access required'
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
    User.joins(:transactions)
        .group('users.id')
        .order('COUNT(transactions.id) DESC')
        .limit(10)
        .map { |u| { user: { id: u.id, name: u.full_name, email: u.email }, activity_count: u.transactions.count } }
  end

  def calculate_user_lifetime_value
    return 0 if User.count.zero?
    avg_transactions = Transaction.count.to_f / User.count
    avg_value = Transaction.average(:amount) || 0
    (avg_transactions * avg_value.abs).round(2)
  end

  def calculate_churn_rate
    total = User.count
    return 0 if total.zero?
    inactive = User.where('updated_at < ?', 30.days.ago).count
    (inactive.to_f / total * 100).round(2)
  end

  def export_users_data(format)
    users = User.includes(:transactions, :accounts)
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Email', 'Full Name', 'Admin', 'Created At', 'Transactions', 'Total Amount']
      users.each { |u| csv << [u.id, u.email, u.full_name, u.admin?, u.created_at, u.transactions.count, u.transactions.sum(:amount)] }
    end
    { content: csv_data, filename: "users_#{Date.current}.csv", content_type: 'text/csv' }
  end

  def export_transactions_data(format)
    transactions = Transaction.includes(:user, :category)
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'User', 'Amount', 'Type', 'Category', 'Date']
      transactions.each { |t| csv << [t.id, t.user.email, t.amount, t.transaction_type, t.category&.name, t.date] }
    end
    { content: csv_data, filename: "transactions_#{Date.current}.csv", content_type: 'text/csv' }
  end

  def handle_error(e)
    Rails.logger.error "Analytics Error: #{e.message}"
    flash[:alert] = "An error occurred loading analytics."
    redirect_to admin_analytics_path
  end

  def handle_analytics_error(e, feature)
    Rails.logger.error "Analytics #{feature} Error: #{e.message}"
    flash[:alert] = "Unable to load #{feature} data."
    redirect_to admin_analytics_path
  end
end
