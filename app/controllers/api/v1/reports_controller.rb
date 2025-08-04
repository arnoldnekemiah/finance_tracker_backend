class Api::V1::ReportsController < ApplicationController
  def monthly_comparison
    current_month = Date.current.beginning_of_month
    previous_month = current_month - 1.month
    
    current_month_transactions = current_user.transactions
      .where(date: current_month..current_month.end_of_month)
      .where(transaction_type: 'expense')
    
    previous_month_transactions = current_user.transactions
      .where(date: previous_month..previous_month.end_of_month)
      .where(transaction_type: 'expense')
    
    current_total = current_month_transactions.sum(:amount)
    previous_total = previous_month_transactions.sum(:amount)
    
    difference = current_total - previous_total
    percentage_change = previous_total.zero? ? 0 : ((difference / previous_total) * 100).round(2)
    
    render json: {
      current_month: {
        month: current_month.strftime('%B %Y'),
        total_expenses: current_total,
        transaction_count: current_month_transactions.count
      },
      previous_month: {
        month: previous_month.strftime('%B %Y'),
        total_expenses: previous_total,
        transaction_count: previous_month_transactions.count
      },
      comparison: {
        difference: difference,
        percentage_change: percentage_change,
        trend: difference > 0 ? 'increased' : 'decreased'
      }
    }
  end

  def spending_by_category
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current.end_of_month
    
    spending_data = current_user.transactions
      .joins(:category)
      .where(transaction_type: 'expense')
      .where(date: start_date..end_date)
      .group('categories.name')
      .sum(:amount)
    
    total_spending = spending_data.values.sum
    
    categories_with_percentages = spending_data.map do |category_name, amount|
      percentage = total_spending.zero? ? 0 : ((amount / total_spending) * 100).round(2)
      {
        category: category_name,
        amount: amount,
        percentage: percentage
      }
    end.sort_by { |item| -item[:amount] }
    
    render json: {
      period: {
        start_date: start_date,
        end_date: end_date
      },
      total_spending: total_spending,
      categories: categories_with_percentages
    }
  end
end
