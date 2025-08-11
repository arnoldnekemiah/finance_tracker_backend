class Api::V1::DashboardController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_authorization_check

  def index
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
        balance_overview: balance_overview,
        monthly_summary: monthly_summary,
        weekly_spending: weekly_spending,
        top_spending_categories: top_spending_categories,
        recent_transactions: recent_transactions,
        quick_stats: quick_stats
      }
    }
  end

  def financial_overview
    user_currency = current_user.effective_currency
    currency_info = current_user.currency_info
    
    # Calculate total assets (regular + savings accounts)
    total_assets = current_user.accounts.asset_accounts.active.sum(:balance)
    
    # Calculate total debts (debt accounts + debt records)
    total_debt_accounts = current_user.accounts.debt_accounts.active.sum(:balance).abs
    total_debt_records = current_user.debts.sum(:amount)
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
        total_assets: format_money(total_assets),
        total_debts: format_money(total_debts),
        net_worth: format_money(net_worth)
      }
    }
  end

  def monthly_summary_by_month
    month = params[:month]&.to_i || Date.current.month
    year = params[:year]&.to_i || Date.current.year
    
    start_of_month = Date.new(year, month, 1)
    end_of_month = start_of_month.end_of_month
    
    # Calculate starting balance (balance at end of previous month)
    previous_month_end = start_of_month - 1.day
    starting_balance = calculate_balance_at_date(previous_month_end)
    
    # Calculate month transactions
    monthly_income = current_user.transactions
      .where(transaction_type: 'income', date: start_of_month..end_of_month)
      .sum(:amount)
    
    monthly_expenses = current_user.transactions
      .where(transaction_type: 'expense', date: start_of_month..end_of_month)
      .sum(:amount)
    
    # Calculate ending balance
    ending_balance = starting_balance + monthly_income - monthly_expenses
    
    user_currency = current_user.effective_currency
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
        starting_balance: format_money(starting_balance),
        ending_balance: format_money(ending_balance),
        total_income: format_money(monthly_income),
        total_expenses: format_money(monthly_expenses),
        net_change: format_money(monthly_income - monthly_expenses)
      }
    }
  end

  private

  def balance_overview
    current_balance = current_user.accounts.active.sum(:balance)
    monthly_income = current_month_income
    monthly_expenses = current_month_expenses
    
    {
      current_balance: format_money(current_balance),
      monthly_income: format_money(monthly_income),
      monthly_expenses: format_money(monthly_expenses),
      net_income: format_money(monthly_income - monthly_expenses)
    }
  end

  def monthly_summary
    monthly_income = current_month_income
    monthly_expenses = current_month_expenses
    total_budget_limit = current_user.budgets.where(
      "start_date <= ? AND end_date >= ?", 
      Date.current, Date.current
    ).sum(:limit)
    
    budget_utilization = total_budget_limit > 0 ? (monthly_expenses / total_budget_limit) : 0
    savings_rate = monthly_income > 0 ? ((monthly_income - monthly_expenses) / monthly_income) : 0
    
    {
      budget_utilization: budget_utilization.round(2),
      income: monthly_income,
      expenses: monthly_expenses,
      savings_rate: savings_rate.round(2)
    }
  end

  def weekly_spending
    start_of_week = Date.current.beginning_of_week
    daily_spending = []
    labels = []
    
    (0..6).each do |day_offset|
      date = start_of_week + day_offset.days
      daily_amount = current_user.transactions
        .where(transaction_type: 'expense', date: date.beginning_of_day..date.end_of_day)
        .sum(:amount)
      
      daily_spending << daily_amount
      labels << date.strftime('%a')
    end
    
    {
      current_week: daily_spending,
      labels: labels
    }
  end

  def top_spending_categories
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month
    
    category_spending = current_user.transactions
      .joins(:category)
      .where(transaction_type: 'expense', date: start_of_month..end_of_month)
      .group('categories.id, categories.name, categories.icon, categories.color')
      .sum(:amount)
    
    total_expenses = category_spending.values.sum
    
    category_spending.map do |(category_id, name, icon, color), amount|
      {
        category_id: category_id,
        category_name: name,
        amount: amount,
        percentage: total_expenses > 0 ? ((amount / total_expenses) * 100).round(1) : 0,
        icon: icon || 'default',
        color: color || '#6B7280'
      }
    end.sort_by { |cat| -cat[:amount] }.first(5)
  end

  def recent_transactions
    current_user.transactions
      .includes(:category)
      .order(date: :desc, created_at: :desc)
      .limit(10)
      .map do |transaction|
        {
          id: transaction.id,
          amount: transaction.amount,
          description: transaction.description,
          category: transaction.category&.name || 'Uncategorized',
          date: transaction.date.iso8601,
          type: transaction.transaction_type
        }
      end
  end

  def quick_stats
    current_month = Date.current.beginning_of_month..Date.current.end_of_month
    
    {
      total_budgets: current_user.budgets.count,
      active_debts: current_user.debts.where(status: ['pending', 'overdue']).count,
      saving_goals: current_user.saving_goals.count,
      transactions_this_month: current_user.transactions.where(date: current_month).count
    }
  end

  def current_month_income
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month
    
    current_user.transactions
      .where(transaction_type: 'income', date: start_of_month..end_of_month)
      .sum(:amount)
  end

  def current_month_expenses
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month
    
    current_user.transactions
      .where(transaction_type: 'expense', date: start_of_month..end_of_month)
      .sum(:amount)
  end
  
  def format_money(amount)
    CurrencyService.format_money(amount, current_user.effective_currency)
  end
  
  def calculate_balance_at_date(date)
    # Start with current account balances
    current_balance = current_user.accounts.active.sum(:balance)
    
    # Calculate transactions from the specified date to now
    transactions_since = current_user.transactions
      .where('date > ?', date.end_of_day)
    
    income_since = transactions_since.where(transaction_type: 'income').sum(:amount)
    expenses_since = transactions_since.where(transaction_type: 'expense').sum(:amount)
    
    # Balance at date = current balance - (income since - expenses since)
    balance_at_date = current_balance - income_since + expenses_since
    
    balance_at_date
  end
end
