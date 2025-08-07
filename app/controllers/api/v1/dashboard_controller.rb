class Api::V1::DashboardController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_authorization_check

  def index
    render json: {
      status: { success: true, message: "Dashboard data retrieved successfully" },
      data: {
        balance_overview: balance_overview,
        monthly_summary: monthly_summary,
        weekly_spending: weekly_spending,
        top_spending_categories: top_spending_categories,
        recent_transactions: recent_transactions,
        quick_stats: quick_stats
      }
    }
  end

  private

  def balance_overview
    current_balance = current_user.accounts.active.sum(:balance)
    monthly_income = current_month_income
    monthly_expenses = current_month_expenses
    
    {
      current_balance: current_balance,
      monthly_income: monthly_income,
      monthly_expenses: monthly_expenses,
      net_income: monthly_income - monthly_expenses
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
end
