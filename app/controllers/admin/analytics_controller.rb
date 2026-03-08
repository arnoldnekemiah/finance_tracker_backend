class Admin::AnalyticsController < Admin::BaseController

  rescue_from StandardError, with: :handle_error

  def index
    # Main analytics dashboard view
  end

  def user_growth
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date   = parse_date(params[:end_date])   || Time.current

    new_users  = User.where(created_at: start_date..end_date)

    @metrics = {
      total_users:              User.count,
      active_users:             User.active_users.count,
      inactive_users:           User.where(active: false).count,
      new_users_period:         new_users.count,
      registrations_by_day:     new_users.group("DATE(created_at)").count,
      registrations_by_month:   User.where('created_at >= ?', 12.months.ago)
                                    .group("DATE_TRUNC('month', created_at)")
                                    .count
                                    .transform_keys { |k| k.to_s[0..6] },
      provider_distribution:    User.group(:provider).count,
      currency_distribution:    User.group(:currency).count,
      retention: {
        users_active_last_7d:  User.joins(:transactions).where('transactions.created_at >= ?', 7.days.ago).distinct.count,
        users_active_last_30d: User.joins(:transactions).where('transactions.created_at >= ?', 30.days.ago).distinct.count
      }
    }
    @start_date = start_date
    @end_date   = end_date
    render :user_growth
  rescue => e
    handle_analytics_error(e, 'user growth')
  end

  def transaction_volume
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date   = parse_date(params[:end_date])   || Time.current
    range      = start_date..end_date

    transactions = Transaction.where(created_at: range)

    @metrics = {
      total_transactions:       transactions.count,
      income_count:             Transaction.income.where(date: range).count,
      expense_count:            Transaction.expense.where(date: range).count,
      transfer_count:           Transaction.transfer.where(date: range).count,
      total_income_volume:      Transaction.income.where(date: range).sum(:amount).to_f.round(2),
      total_expense_volume:     Transaction.expense.where(date: range).sum(:amount).to_f.round(2),
      net_volume:               (Transaction.income.where(date: range).sum(:amount) -
                                  Transaction.expense.where(date: range).sum(:amount)).to_f.round(2),
      avg_transaction_amount:   (Transaction.where(date: range).average(:amount) || 0).to_f.round(2),
      transactions_by_day:      transactions.group("DATE(created_at)").count,
      income_by_day:            Transaction.income.where(date: range).group("DATE(date)").sum(:amount)
                                           .transform_values { |v| v.to_f.round(2) },
      expenses_by_day:          Transaction.expense.where(date: range).group("DATE(date)").sum(:amount)
                                           .transform_values { |v| v.to_f.round(2) },
      payment_method_breakdown: Transaction.where(date: range).group(:payment_method).count
    }
    @start_date = start_date
    @end_date   = end_date
    render :transaction_volume
  rescue => e
    handle_analytics_error(e, 'transaction volume')
  end

  def financial_insights
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date   = parse_date(params[:end_date])   || Time.current

    total_income   = Transaction.income.where(date: start_date..end_date).sum(:amount).to_f
    total_expenses = Transaction.expense.where(date: start_date..end_date).sum(:amount).to_f
    net_savings    = (total_income - total_expenses).round(2)
    savings_rate   = total_income > 0 ? ((net_savings / total_income) * 100).round(2) : 0

    @insights = {
      total_income:           total_income.round(2),
      total_expenses:         total_expenses.round(2),
      net_savings:            net_savings,
      savings_rate:           savings_rate,
      avg_transaction:        (Transaction.where(date: start_date..end_date).average(:amount) || 0).to_f.round(2),

      # Top expense categories
      top_expense_categories: Transaction.expense
                                         .where(date: start_date..end_date)
                                         .joins(:category)
                                         .group('categories.name')
                                         .sum(:amount)
                                         .sort_by { |_, v| -v.to_f }
                                         .first(10)
                                         .map { |name, amt| { category: name, amount: amt.to_f.round(2) } },

      # Top income categories
      top_income_categories:  Transaction.income
                                         .where(date: start_date..end_date)
                                         .joins(:category)
                                         .group('categories.name')
                                         .sum(:amount)
                                         .sort_by { |_, v| -v.to_f }
                                         .first(10)
                                         .map { |name, amt| { category: name, amount: amt.to_f.round(2) } },

      # Platform account health
      total_account_balance:        Account.active.sum(:balance).to_f.round(2),
      asset_account_balance:        Account.active.asset_accounts.sum(:balance).to_f.round(2),
      debt_account_balance:         Account.active.debt_accounts.sum(:balance).to_f.round(2),

      # Debts overview
      total_outstanding_debt:       Debt.where(status: %w[pending overdue]).sum(:amount).to_f.round(2),
      overdue_debt:                 Debt.overdue.sum(:amount).to_f.round(2),

      # Saving goals overview
      total_saving_goal_progress:   {
        target: SavingGoal.sum(:target_amount).to_f.round(2),
        saved:  SavingGoal.sum(:current_amount).to_f.round(2)
      }
    }
    @start_date = start_date
    @end_date   = end_date
    render :financial_insights
  rescue => e
    handle_analytics_error(e, 'financial insights')
  end

  def user_activity
    # Use transaction-based activity for accurate engagement metrics
    @activities = Transaction.where(created_at: date_range)
                             .group("DATE(created_at)")
                             .count

    @top_active_users = top_active_users

    # Users with recent transactions (last 30 days)
    @active_user_ids = Transaction.where('created_at >= ?', 30.days.ago)
                                  .distinct
                                  .pluck(:user_id)

    @recent_activities = Transaction.includes(:user)
                                    .where('transactions.created_at >= ?', 7.days.ago)
                                    .order('transactions.created_at DESC')
                                    .limit(20)
                                    .map do |t|
                                      {
                                        user:       { id: t.user.id, name: t.user.full_name, email: t.user.email },
                                        event_type: t.transaction_type,
                                        amount:     t.amount.to_f,
                                        created_at: t.created_at
                                      }
                                    end

    @engagement_metrics = {
      users_with_transactions:    Transaction.distinct.count(:user_id),
      users_without_transactions: User.count - Transaction.distinct.count(:user_id),
      avg_transactions_per_user:  User.count.zero? ? 0 : (Transaction.count.to_f / User.count).round(2),
      avg_monthly_transactions:   avg_monthly_transactions_per_active_user
    }

    render :user_activity
  end

  def revenue_analytics
    @revenue_data = {
      # User base
      total_users:       User.count,
      active_users:      User.active_users.count,
      churn_rate:        calculate_churn_rate,

      # Financial platform value
      platform_aum:      Account.active.asset_accounts.sum(:balance).to_f.round(2),  # assets under management
      total_debt_tracked: Debt.where(status: %w[pending overdue]).sum(:amount).to_f.round(2),
      total_savings_tracked: SavingGoal.sum(:current_amount).to_f.round(2),

      # Transaction-based value metrics
      avg_user_transaction_volume: calculate_avg_user_transaction_volume,
      user_lifetime_value:         calculate_user_lifetime_value,

      # Monthly recurring metrics (last 6 months)
      monthly_transaction_volume: monthly_transaction_volume(6),

      # User segments by financial activity
      user_segments: {
        high_activity:   User.joins(:transactions).group('users.id').having('COUNT(transactions.id) >= 20').count.size,
        medium_activity: User.joins(:transactions).group('users.id').having('COUNT(transactions.id) BETWEEN 5 AND 19').count.size,
        low_activity:    User.joins(:transactions).group('users.id').having('COUNT(transactions.id) BETWEEN 1 AND 4').count.size,
        no_activity:     User.count - User.joins(:transactions).distinct.count
      }
    }
    render :revenue_analytics
  rescue => e
    handle_analytics_error(e, 'revenue analytics')
  end

  def export_data
    format    = params[:format]    || 'csv'
    data_type = params[:data_type] || 'users'

    case data_type
    when 'users'        then data = export_users_data(format)
    when 'transactions' then data = export_transactions_data(format)
    when 'debts'        then data = export_debts_data(format)
    when 'saving_goals' then data = export_saving_goals_data(format)
    else
      return render json: { error: 'Invalid data type. Supported: users, transactions, debts, saving_goals' }, status: :bad_request
    end

    send_data data[:content], filename: data[:filename], type: data[:content_type]
  end

  private

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end

  def date_range
    start_date = parse_date(params[:start_date]) || 30.days.ago
    end_date   = parse_date(params[:end_date])   || Time.current
    start_date..end_date
  end

  def top_active_users
    User.joins(:transactions)
        .select("users.id, users.first_name, users.last_name, users.email, COUNT(transactions.id) AS transaction_count, SUM(transactions.amount) AS total_volume")
        .group('users.id, users.first_name, users.last_name, users.email')
        .order('transaction_count DESC')
        .limit(10)
        .map do |u|
          {
            user:              { id: u.id, name: "#{u.first_name} #{u.last_name}", email: u.email },
            transaction_count: u.transaction_count.to_i,
            total_volume:      u.total_volume.to_f.round(2)
          }
        end
  end

  def avg_monthly_transactions_per_active_user
    active_count = User.joins(:transactions).distinct.count
    return 0 if active_count.zero?
    monthly_avg = Transaction.where('created_at >= ?', 30.days.ago).count.to_f / active_count
    monthly_avg.round(2)
  end

  def monthly_transaction_volume(months = 6)
    results = []
    months.times do |i|
      period_start = i.months.ago.beginning_of_month
      period_end   = i.months.ago.end_of_month
      results << {
        month:    period_start.strftime('%Y-%m'),
        income:   Transaction.income.where(date: period_start..period_end).sum(:amount).to_f.round(2),
        expenses: Transaction.expense.where(date: period_start..period_end).sum(:amount).to_f.round(2),
        count:    Transaction.where(date: period_start..period_end).count
      }
    end
    results.reverse
  end

  def calculate_user_lifetime_value
    return 0 if User.count.zero?
    avg_transactions = Transaction.count.to_f / User.count
    avg_value = (Transaction.average(:amount) || 0).to_f
    (avg_transactions * avg_value).round(2)
  end

  def calculate_avg_user_transaction_volume
    active_users = User.joins(:transactions).distinct.count
    return 0 if active_users.zero?
    (Transaction.sum(:amount).to_f / active_users).round(2)
  end

  def calculate_churn_rate
    total = User.count
    return 0 if total.zero?
    # Users with no transactions in the last 30 days are considered inactive/churned
    inactive = total - User.joins(:transactions).where('transactions.created_at >= ?', 30.days.ago).distinct.count
    (inactive.to_f / total * 100).round(2)
  end

  def export_users_data(_format)
    users = User.includes(:transactions, :accounts, :debts, :saving_goals)
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Email', 'Full Name', 'Admin', 'Active', 'Provider', 'Currency', 'Created At',
              'Transactions', 'Total Income', 'Total Expenses', 'Accounts', 'Active Debts', 'Saving Goals']
      users.each do |u|
        csv << [
          u.id, u.email, u.full_name, u.admin?, u.is_active, u.provider || 'email', u.currency, u.created_at,
          u.transactions.count,
          u.transactions.income.sum(:amount).to_f.round(2),
          u.transactions.expense.sum(:amount).to_f.round(2),
          u.accounts.count,
          u.debts.where(status: %w[pending overdue]).count,
          u.saving_goals.count
        ]
      end
    end
    { content: csv_data, filename: "users_#{Date.current}.csv", content_type: 'text/csv' }
  end

  def export_transactions_data(_format)
    transactions = Transaction.includes(:user, :category)
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'User Email', 'Amount', 'Type', 'Category', 'Description', 'Payment Method', 'Date', 'Created At']
      transactions.each do |t|
        csv << [t.id, t.user.email, t.amount.to_f, t.transaction_type, t.category&.name, t.description, t.payment_method, t.date, t.created_at]
      end
    end
    { content: csv_data, filename: "transactions_#{Date.current}.csv", content_type: 'text/csv' }
  end

  def export_debts_data(_format)
    debts = Debt.includes(:user)
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'User Email', 'Title', 'Amount', 'Creditor', 'Status', 'Debt Type', 'Due Date', 'Interest Rate', 'Recurring']
      debts.each do |d|
        csv << [d.id, d.user.email, d.title, d.amount.to_f, d.creditor, d.status, d.debt_type, d.due_date, d.interest_rate, d.is_recurring]
      end
    end
    { content: csv_data, filename: "debts_#{Date.current}.csv", content_type: 'text/csv' }
  end

  def export_saving_goals_data(_format)
    goals = SavingGoal.includes(:user)
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['ID', 'User Email', 'Title', 'Target Amount', 'Current Amount', 'Progress %', 'Target Date', 'Achieved', 'Created At']
      goals.each do |g|
        progress = g.target_amount > 0 ? ((g.current_amount / g.target_amount) * 100).round(1) : 0
        csv << [g.id, g.user.email, g.title, g.target_amount.to_f, g.current_amount.to_f, progress, g.target_date, g.current_amount >= g.target_amount, g.created_at]
      end
    end
    { content: csv_data, filename: "saving_goals_#{Date.current}.csv", content_type: 'text/csv' }
  end

  def handle_error(e)
    Rails.logger.error "Analytics Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    flash[:alert] = "An error occurred loading analytics."
    redirect_to admin_analytics_path
  end

  def handle_analytics_error(e, feature)
    Rails.logger.error "Analytics #{feature} Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    flash[:alert] = "Unable to load #{feature} data."
    redirect_to admin_analytics_path
  end
end
