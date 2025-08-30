class Api::V1::DashboardController < ApplicationController
  include ActionController::Caching
  
  skip_before_action :verify_authenticity_token
  skip_authorization_check
  
  # Enable page and action caching
  caches_page :index, :financial_overview, :monthly_summary_by_month, if: -> { Rails.env.production? }
  
  before_action :set_cache_headers
  
  def set_cache_headers
    expires_in 1.hour, public: true
  end

  def index
    account_id = params[:account_id]
    user_currency = current_user.effective_currency
    currency_info = current_user.currency_info
    
    render json: {
      status: { success: true, message: "Dashboard data retrieved successfully" },
      data: {
        currency: {
          code: user_currency,
          symbol: currency_info[:symbol],
          name: currency_info[:name]
        },
        balance_overview: balance_overview(account_id),
        monthly_summary: monthly_summary(account_id),
        weekly_spending: weekly_spending(account_id),
        top_spending_categories: top_spending_categories(account_id),
        recent_transactions: recent_transactions(account_id),
        quick_stats: quick_stats(account_id)
      }
    }
  end

  def financial_overview
    user_currency = current_user.effective_currency
    currency_info = current_user.currency_info
    
    # Calculate total assets (regular + savings accounts)
    total_assets = current_user.accounts.asset_accounts.active.map { |a| a.balance.exchange_to(user_currency) }.sum
    
    # Calculate total debts (debt accounts + debt records)
    total_debt_accounts = current_user.accounts.debt_accounts.active.map { |a| a.balance.exchange_to(user_currency) }.sum.abs
    total_debt_records = current_user.debts.map { |d| d.amount.exchange_to(user_currency) }.sum
    total_debts = total_debt_accounts + total_debt_records
    
    # Calculate net worth
    net_worth = total_assets - total_debts
    
    render json: {
      status: { success: true, message: "Financial overview retrieved successfully" },
      data: {
        currency: {
          code: user_currency,
          symbol: currency_info[:symbol],
          name: currency_info[:name]
        },
        total_assets: format_money(total_assets.amount),
        total_debts: format_money(total_debts.amount),
        net_worth: format_money(net_worth.amount)
      }
    }
  end

  def monthly_summary_by_month
    month = params[:month]&.to_i || Date.current.month
    year = params[:year]&.to_i || Date.current.year
    user_currency = current_user.effective_currency
    
    start_of_month = Date.new(year, month, 1)
    end_of_month = start_of_month.end_of_month
    
    # Calculate starting balance (balance at end of previous month)
    previous_month_end = start_of_month - 1.day
    starting_balance = calculate_balance_at_date(previous_month_end)
    
    # Calculate month transactions
    monthly_income = current_user.transactions
      .where(transaction_type: 'income', date: start_of_month..end_of_month)
      .map { |t| t.original_amount.exchange_to(user_currency) }.sum
    
    monthly_expenses = current_user.transactions
      .where(transaction_type: 'expense', date: start_of_month..end_of_month)
      .map { |t| t.original_amount.exchange_to(user_currency) }.sum
    
    # Calculate ending balance
    ending_balance = starting_balance + monthly_income - monthly_expenses
    
    currency_info = current_user.currency_info
    
    render json: {
      status: { success: true, message: "Monthly summary retrieved successfully" },
      data: {
        currency: {
          code: user_currency,
          symbol: currency_info[:symbol],
          name: currency_info[:name]
        },
        month: month,
        year: year,
        starting_balance: format_money(starting_balance.amount),
        ending_balance: format_money(ending_balance.amount),
        total_income: format_money(monthly_income.amount),
        total_expenses: format_money(monthly_expenses.amount),
        net_change: format_money((monthly_income - monthly_expenses).amount)
      }
    }
  end

  private

  def dashboard_cache_path
    cache_key = "dashboard_#{current_user.id}_#{action_name}"
    if action_name == 'monthly_summary_by_month'
      cache_key += "_#{params[:month]}_#{params[:year]}"
    end
    if params[:account_id].present?
      cache_key += "_account_#{params[:account_id]}"
    end
    cache_key
  end

  def balance_overview(account_id = nil)
    user_currency = current_user.effective_currency
    accounts = account_id ? current_user.accounts.where(id: account_id) : current_user.accounts.active
    current_balance = accounts.map { |a| a.balance.exchange_to(user_currency) }.sum
    monthly_income = current_month_income(account_id)
    monthly_expenses = current_month_expenses(account_id)
    
    {
      current_balance: format_money(current_balance.amount),
      monthly_income: format_money(monthly_income.amount),
      monthly_expenses: format_money(monthly_expenses.amount),
      net_income: format_money((monthly_income - monthly_expenses).amount)
    }
  end

  def monthly_summary(account_id = nil)
    monthly_income = current_month_income(account_id)
    monthly_expenses = current_month_expenses(account_id)
    user_currency = current_user.effective_currency
    total_budget_limit = current_user.budgets.where(
      "start_date <= ? AND end_date >= ?", 
      Date.current, Date.current
    ).map { |b| b.limit.exchange_to(user_currency) }.sum
    
    budget_utilization = total_budget_limit.amount > 0 ? (monthly_expenses.amount / total_budget_limit.amount) : 0
    savings_rate = monthly_income.amount > 0 ? ((monthly_income.amount - monthly_expenses.amount) / monthly_income.amount) : 0
    
    {
      budget_utilization: budget_utilization.round(2),
      income: monthly_income.amount,
      expenses: monthly_expenses.amount,
      savings_rate: savings_rate.round(2)
    }
  end

  def weekly_spending(account_id = nil)
    start_of_week = Date.current.beginning_of_week
    user_currency = current_user.effective_currency
    daily_spending = []
    labels = []
    
    (0..6).each do |day_offset|
      date = start_of_week + day_offset.days
      transactions = current_user.transactions.where(transaction_type: 'expense', date: date.beginning_of_day..date.end_of_day)
      transactions = transactions.where(from_account_id: account_id) if account_id
      daily_amount = transactions.map { |t| t.original_amount.exchange_to(user_currency) }.sum
      
      daily_spending << daily_amount.amount
      labels << date.strftime('%a')
    end
    
    {
      current_week: daily_spending,
      labels: labels
    }
  end

  def top_spending_categories(account_id = nil)
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month
    user_currency = current_user.effective_currency
    
    transactions = current_user.transactions
      .includes(:category)
      .where(transaction_type: 'expense', date: start_of_month..end_of_month)
    transactions = transactions.where(from_account_id: account_id) if account_id

    total_expenses = transactions.map { |t| t.original_amount.exchange_to(user_currency) }.sum

    category_spending = transactions.group_by(&:category).map do |category, trans|
      {
        category: category,
        amount: trans.map { |t| t.original_amount.exchange_to(user_currency) }.sum
      }
    end

    category_spending.map do |data|
      category = data[:category]
      amount = data[:amount]
      {
        category_id: category&.id,
        category_name: category&.name || 'Uncategorized',
        amount: amount.amount,
        percentage: total_expenses.amount > 0 ? ((amount.amount / total_expenses.amount) * 100).round(1) : 0,
        icon: category&.icon || 'default',
        color: category&.color || '#6B7280'
      }
    end.sort_by { |cat| -cat[:amount] }.first(5)
  end

  def recent_transactions(account_id = nil)
    transactions = current_user.transactions
      .includes(:category)
      .order(date: :desc, created_at: :desc)

    if account_id
      transactions = transactions.where("from_account_id = ? OR to_account_id = ?", account_id, account_id)
    end

    transactions.limit(10).map do |transaction|
      {
        id: transaction.id,
        amount: transaction.original_amount.format,
        description: transaction.description,
        category: transaction.category&.name || 'Uncategorized',
        date: transaction.date.iso8601,
        type: transaction.transaction_type
      }
    end
  end

  def quick_stats(account_id = nil)
    current_month = Date.current.beginning_of_month..Date.current.end_of_month
    
    transactions = current_user.transactions.where(date: current_month)
    if account_id
      transactions = transactions.where("from_account_id = ? OR to_account_id = ?", account_id, account_id)
    end

    {
      total_budgets: current_user.budgets.count,
      active_debts: current_user.debts.where(status: ['pending', 'overdue']).count,
      saving_goals: current_user.saving_goals.count,
      transactions_this_month: transactions.count
    }
  end

  def current_month_income(account_id = nil)
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month
    user_currency = current_user.effective_currency
    
    transactions = current_user.transactions.where(transaction_type: 'income', date: start_of_month..end_of_month)
    transactions = transactions.where(to_account_id: account_id) if account_id
    transactions.map { |t| t.original_amount.exchange_to(user_currency) }.sum
  end

  def current_month_expenses(account_id = nil)
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month
    user_currency = current_user.effective_currency
    
    transactions = current_user.transactions.where(transaction_type: 'expense', date: start_of_month..end_of_month)
    transactions = transactions.where(from_account_id: account_id) if account_id
    transactions.map { |t| t.original_amount.exchange_to(user_currency) }.sum
  end
  
  def format_money(amount)
    CurrencyService.format_money(amount, current_user.effective_currency)
  end
  
  def calculate_balance_at_date(date)
    user_currency = current_user.effective_currency
    # Start with current account balances
    current_balance = current_user.accounts.active.map { |a| a.balance.exchange_to(user_currency) }.sum
    
    # Calculate transactions from the specified date to now
    transactions_since = current_user.transactions
      .where('date > ?', date.end_of_day)
    
    income_since = transactions_since.where(transaction_type: 'income').map { |t| t.original_amount.exchange_to(user_currency) }.sum
    expenses_since = transactions_since.where(transaction_type: 'expense').map { |t| t.original_amount.exchange_to(user_currency) }.sum
    
    # Balance at date = current balance - (income since - expenses since)
    balance_at_date = current_balance - income_since + expenses_since
    
    balance_at_date
  end
end
