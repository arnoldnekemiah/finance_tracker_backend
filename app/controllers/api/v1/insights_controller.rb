class Api::V1::InsightsController < ApplicationController
  # Skip CanCanCan authorization since we're already authenticating the user
  # and all data is scoped to current_user
  skip_authorization_check
  
  rescue_from StandardError do |e|
    Rails.logger.error "Insights Error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: 'An error occurred while processing insights' }, status: :internal_server_error
  end
  
  def overview
    monthly_data = {
      total_income: current_user.transactions.income.this_month.sum(:amount) || 0,
      total_expenses: current_user.transactions.expense.this_month.sum(:amount) || 0,
      top_categories: top_spending_categories,
      monthly_trend: calculate_monthly_trend
    }
    
    render json: { data: monthly_data }, status: :ok
  rescue StandardError => error
    Rails.logger.error "Overview Error: #{error.message}\n#{error.backtrace.join("\n")}"
    render json: { error: 'Failed to fetch overview data', details: error.message }, status: :unprocessable_entity
  end

  def spending_by_category
    categories = current_user.transactions
                           .expense
                           .where('date >= ?', 30.days.ago)
                           .group(:category_id)
                           .sum(:amount)
    
    render json: { data: categories }, status: :ok
  rescue StandardError => error
    Rails.logger.error "Spending by category error: #{error.message}"
    render json: { error: 'Failed to fetch category data' }, status: :unprocessable_entity
  end

  def spending_comparison
    current_month = current_user.transactions.expense.this_month.sum(:amount) || 0
    last_month = current_user.transactions.expense.last_month.sum(:amount) || 0
    
    comparison = {
      current_month: current_month,
      last_month: last_month,
      percentage_change: calculate_percentage_change(current_month, last_month)
    }
    
    render json: { data: comparison }, status: :ok
  rescue StandardError => error
    Rails.logger.error "Spending comparison error: #{error.message}"
    render json: { error: 'Failed to fetch comparison data' }, status: :unprocessable_entity
  end

  def weekly_trends
    weekly_data = current_user.transactions
                            .expense
                            .where('date >= ?', 1.week.ago)
                            .group("DATE(date)")
                            .sum(:amount)
    
    render json: { data: weekly_data }, status: :ok
  rescue StandardError => error
    Rails.logger.error "Weekly trends error: #{error.message}"
    render json: { error: 'Failed to fetch weekly trends' }, status: :unprocessable_entity
  end
  
  private
  
  def calculate_percentage_change(current_month, last_month)
    return 100 if last_month.zero? && current_month.positive?
    return -100 if last_month.zero? && current_month.negative?
    return 0 if last_month.zero?
    ((current_month - last_month) / last_month.to_f * 100).round(2)
  end

  def top_spending_categories(limit = 5)
    current_user.transactions
               .expense
               .where('date >= ?', 30.days.ago)
               .joins(:category)
               .group('categories.name')
               .select('categories.name as category_name, SUM(amount) as total_amount')
               .order('total_amount DESC')
               .limit(limit)
               .map { |t| { category: t.category_name, amount: t.total_amount } }
  end

  def calculate_monthly_trend(months = 6)
    end_date = Date.current.end_of_month
    start_date = (end_date - (months - 1).months).beginning_of_month
    
    transactions = current_user.transactions
                             .where(date: start_date..end_date)
                             .group("DATE_TRUNC('month', date)")
                             .group(:type)
                             .sum(:amount)
    
    # Initialize result hash with all months
    result = {}
    months.times do |i|
      date = (end_date - i.months).beginning_of_month
      result[date.strftime('%b %Y')] = { income: 0, expense: 0 }
    end
    
    # Fill in the actual data
    transactions.each do |(date, type), amount|
      month_key = date.strftime('%b %Y')
      if result[month_key]
        result[month_key][:income] = amount if type == 'income'
        result[month_key][:expense] = amount.abs if type == 'expense'
      end
    end
    
    result.sort.reverse.to_h
  end
end
