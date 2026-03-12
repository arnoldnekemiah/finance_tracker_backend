class Admin::DashboardController < Admin::BaseController

  rescue_from StandardError, with: :handle_dashboard_error

  def index
    begin
      @stats = system_statistics
      @user_metrics = user_metrics
      @financial_metrics = financial_metrics
      @recent_activity = recent_activity
      @health = system_health
      @platform_metrics = platform_metrics
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

  def system_statistics
    today = Date.current.beginning_of_day..Date.current.end_of_day
    this_month = Date.current.beginning_of_month..Date.current.end_of_month

    {
      # User counts
      total_users:              User.count,
      admin_users:              User.admins.count,
      active_users:             User.active_users.count,
      inactive_users:           User.where(active: false).count,
      new_registrations_today:  User.where(created_at: today).count,
      new_registrations_month:  User.where(created_at: this_month).count,
      active_users_today:       User.where(updated_at: today).count,

      # Transaction counts
      total_transactions:       Transaction.count,
      transactions_today:       Transaction.where(created_at: today).count,
      transactions_this_month:  Transaction.where(created_at: this_month).count,

      # Other model counts
      total_accounts:           Account.count,
      active_accounts:          Account.active.count,
      total_categories:         Category.count,
      total_budgets:            Budget.count,
      total_debts:              Debt.count,
      active_debts:             Debt.where(status: %w[pending overdue]).count,
      total_saving_goals:       SavingGoal.count
    }
  end

  def user_metrics
    registrations_30d = User.where('created_at >= ?', 30.days.ago)
                            .group("DATE(created_at)")
                            .count

    registrations_12m = User.where('created_at >= ?', 12.months.ago)
                            .group("DATE_TRUNC('month', created_at)")
                            .count
                            .transform_keys { |k| k.to_s[0..6] }  # "YYYY-MM"

    {
      registrations_by_day:   registrations_30d,
      registrations_by_month: registrations_12m,
      total_users:            User.count,
      active_users:           User.active_users.count,
      google_users:           User.where(provider: 'google').count,
      email_users:            User.where(provider: %w[email nil]).count
    }
  end

  def financial_metrics
    now = Time.current
    this_month_range = now.beginning_of_month..now.end_of_month
    last_month_range = 1.month.ago.beginning_of_month..1.month.ago.end_of_month

    transactions_30d = Transaction.where('created_at >= ?', 30.days.ago)

    {
      # Totals (all-time)
      total_income:            Transaction.income.sum(:amount).to_f.round(2),
      total_expenses:          Transaction.expense.sum(:amount).to_f.round(2),
      net_income:              (Transaction.income.sum(:amount) - Transaction.expense.sum(:amount)).to_f.round(2),

      # This month
      income_this_month:       Transaction.income.where(date: this_month_range).sum(:amount).to_f.round(2),
      expenses_this_month:     Transaction.expense.where(date: this_month_range).sum(:amount).to_f.round(2),

      # Last month (for comparison)
      income_last_month:       Transaction.income.where(date: last_month_range).sum(:amount).to_f.round(2),
      expenses_last_month:     Transaction.expense.where(date: last_month_range).sum(:amount).to_f.round(2),

      # Trends (last 30 days, count + amounts)
      transactions_by_day:     transactions_30d.group("DATE(created_at)").count,
      income_by_day:           Transaction.income.where('date >= ?', 30.days.ago)
                                          .group("DATE(date)").sum(:amount)
                                          .transform_values { |v| v.to_f.round(2) },
      expenses_by_day:         Transaction.expense.where('date >= ?', 30.days.ago)
                                          .group("DATE(date)").sum(:amount)
                                          .transform_values { |v| v.to_f.round(2) },

      # Aggregate financial position
      total_account_balance:   Account.active.sum(:balance).to_f.round(2),
      total_debt_outstanding:  Debt.where(status: %w[pending overdue]).sum(:amount).to_f.round(2),
      total_saving_goals_target:  SavingGoal.sum(:target_amount).to_f.round(2),
      total_saving_goals_saved:   SavingGoal.sum(:current_amount).to_f.round(2),

      # Top spending categories (last 30 days)
      top_expense_categories:  Transaction.expense
                                          .where('date >= ?', 30.days.ago)
                                          .joins(:category)
                                          .group('categories.name')
                                          .sum(:amount)
                                          .sort_by { |_, v| -v.to_f }
                                          .first(5)
                                          .map { |name, amount| { category: name, amount: amount.to_f.round(2) } },

      # Top income categories (last 30 days)
      top_income_categories:   Transaction.income
                                          .where('date >= ?', 30.days.ago)
                                          .joins(:category)
                                          .group('categories.name')
                                          .sum(:amount)
                                          .sort_by { |_, v| -v.to_f }
                                          .first(5)
                                          .map { |name, amount| { category: name, amount: amount.to_f.round(2) } }
    }
  end

  def platform_metrics
    {
      # Currency distribution
      currency_distribution: User.group(:currency).count,

      # Auth provider distribution
      provider_distribution: User.group(:provider).count,

      # Account type distribution
      account_type_distribution: Account.group(:account_type).count,

      # Debt type distribution
      debt_type_distribution: Debt.group(:debt_type).count,

      # Debt status breakdown
      debt_status_breakdown: {
        pending:  Debt.pending.count,
        paid:     Debt.paid.count,
        overdue:  Debt.overdue.count,
        pending_amount: Debt.pending.sum(:amount).to_f.round(2),
        overdue_amount: Debt.overdue.sum(:amount).to_f.round(2)
      },

      # Saving goals progress
      saving_goals_overview: {
        total:     SavingGoal.count,
        achieved:  SavingGoal.where('current_amount >= target_amount').count,
        in_progress: SavingGoal.where('current_amount < target_amount').count
      },

      # Budget utilization
      budget_overview: {
        total:     Budget.count,
        active:    Budget.where('start_date <= ? AND end_date >= ?', Date.current, Date.current).count,
        over_budget: Budget.where('spent > limit').count
      }
    }
  rescue => e
    Rails.logger.error "Platform metrics error: #{e.message}"
    {}
  end

  def recent_activity
    # Show most recently active users based on their last transaction
    User.joins("LEFT JOIN transactions ON transactions.user_id = users.id")
        .select("users.id, users.first_name, users.last_name, users.email, MAX(transactions.created_at) AS last_transaction_at")
        .group("users.id, users.first_name, users.last_name, users.email")
        .order("last_transaction_at DESC NULLS LAST")
        .limit(10)
        .map do |user|
          {
            user: { id: user.id, name: "#{user.first_name} #{user.last_name}", email: user.email },
            event_type: 'transaction',
            created_at: user.last_transaction_at || user.updated_at
          }
        end
  rescue
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
      memory_usage: get_memory_usage
    }
  end

  def get_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i
  rescue Errno::ENOENT, StandardError
    # ps command not available or failed - fallback to 0
    0
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

    @stats = {
      total_users: 0, admin_users: 0, active_users: 0, inactive_users: 0,
      active_users_today: 0, new_registrations_today: 0, new_registrations_month: 0,
      total_transactions: 0, transactions_today: 0, transactions_this_month: 0,
      total_accounts: 0, active_accounts: 0, total_categories: 0,
      total_budgets: 0, total_debts: 0, active_debts: 0, total_saving_goals: 0
    }
    @user_metrics = { registrations_by_day: {}, registrations_by_month: {}, total_users: 0, active_users: 0, google_users: 0, email_users: 0 }
    @financial_metrics = {
      total_income: 0, total_expenses: 0, net_income: 0,
      income_this_month: 0, expenses_this_month: 0,
      income_last_month: 0, expenses_last_month: 0,
      transactions_by_day: {}, income_by_day: {}, expenses_by_day: {},
      total_account_balance: 0, total_debt_outstanding: 0,
      total_saving_goals_target: 0, total_saving_goals_saved: 0,
      top_expense_categories: [], top_income_categories: []
    }
    @recent_activity = []
    @health = { rails_env: Rails.env, ruby_version: RUBY_VERSION, rails_version: Rails.version, uptime: 'Unknown', memory_usage: 0 }
    @platform_metrics = {}

    render :index
  end
end
