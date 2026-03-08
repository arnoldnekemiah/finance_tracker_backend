class Api::V1::InsightsController < Api::BaseController
  include Authenticatable

  # GET /api/v1/insights/monthly_overview
  def monthly_overview
    render json: {
      status: 'success',
      data: {
        total_income: current_user.transactions.income.this_month.sum(:amount) || 0,
        total_expenses: current_user.transactions.expense.this_month.sum(:amount) || 0,
        top_categories: top_spending_categories
      }
    }
  end

  # GET /api/v1/insights/spending_by_category
  def spending_by_category
    categories = current_user.transactions
                            .expense
                            .where('date >= ?', 30.days.ago)
                            .joins(:category)
                            .group('categories.id, categories.name, categories.icon, categories.color')
                            .sum(:amount)

    total = categories.values.sum

    data = categories.map do |(cat_id, name, icon, color), amount|
      {
        category_id: cat_id,
        category_name: name,
        icon: icon,
        color: color,
        amount: amount,
        percentage: total > 0 ? ((amount / total) * 100).round(1) : 0
      }
    end.sort_by { |c| -c[:amount] }

    render json: { status: 'success', data: data }
  end

  # GET /api/v1/insights/weekly_trends
  def weekly_trends
    weeks = []
    4.times do |i|
      week_start = (i.weeks.ago).beginning_of_week
      week_end = week_start.end_of_week

      spending = current_user.transactions
                            .expense
                            .where(date: week_start..week_end)
                            .sum(:amount)

      weeks << {
        week: "Week #{4 - i}",
        start_date: week_start.to_date,
        end_date: week_end.to_date,
        spending: spending
      }
    end

    render json: { status: 'success', data: weeks.reverse }
  end

  # GET /api/v1/insights/spending_comparison
  def spending_comparison
    current_month = current_user.transactions.expense.this_month.sum(:amount) || 0
    last_month = current_user.transactions.expense.last_month.sum(:amount) || 0
    percentage_change = calculate_percentage_change(current_month, last_month)

    render json: {
      status: 'success',
      data: {
        current_month: current_month,
        last_month: last_month,
        percentage_change: percentage_change
      }
    }
  end

  private

  def calculate_percentage_change(current_val, previous_val)
    return 100 if previous_val.zero? && current_val.positive?
    return -100 if previous_val.zero? && current_val.negative?
    return 0 if previous_val.zero?
    ((current_val - previous_val) / previous_val.to_f * 100).round(2)
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
end
