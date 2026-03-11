class Api::V1::InsightsController < Api::BaseController
  include Authenticatable

  # GET /api/v1/insights/monthly_overview
  def monthly_overview
    render json: {
      status: 'success',
      data: {
        total_income: (current_user.transactions.income.this_month.sum(:amount) || 0).to_f,
        total_expenses: (current_user.transactions.expense.this_month.sum(:amount) || 0).to_f,
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
        amount: amount.to_f,
        percentage: total > 0 ? ((amount / total) * 100).round(1).to_f : 0.0
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
        week: (4 - i),
        start_date: week_start.to_date,
        end_date: week_end.to_date,
        spending: spending.to_f
      }
    end

    render json: { status: 'success', data: weeks.reverse }
  end

  # GET /api/v1/insights/spending_comparison
  def spending_comparison
    current_month = (current_user.transactions.expense.this_month.sum(:amount) || 0).to_f
    last_month = (current_user.transactions.expense.last_month.sum(:amount) || 0).to_f
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

  # GET /api/v1/insights/monthly_trends  (last 6 months)
  def monthly_trends
    months = []
    6.times do |i|
      ref   = i.months.ago
      start = ref.beginning_of_month
      stop  = ref.end_of_month

      txns = current_user.transactions.where(date: start..stop)
      income   = txns.income.sum(:amount)
      expenses = txns.expense.sum(:amount)

      months << {
        month:    ref.strftime('%b %Y'),
        year:     ref.year,
        month_num: ref.month,
        income:   income,
        expenses: expenses,
        net:      income - expenses
      }
    end

    render json: { status: 'success', data: months.reverse }
  end

  # GET /api/v1/insights/income_vs_expense  (current month detail)
  def income_vs_expense
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date   = params[:end_date]   ? Date.parse(params[:end_date])   : Date.current.end_of_month

    txns = current_user.transactions.where(date: start_date..end_date)

    total_income   = txns.income.sum(:amount)
    total_expenses = txns.expense.sum(:amount)
    net            = total_income - total_expenses
    savings_rate   = total_income > 0 ? ((net / total_income) * 100).round(1) : 0

    income_by_cat = txns.income.joins(:category)
                        .group('categories.name, categories.icon, categories.color')
                        .sum(:amount)
                        .map { |(name, icon, color), amt| { name: name, icon: icon, color: color, amount: amt } }
                        .sort_by { |c| -c[:amount] }

    expense_by_cat = txns.expense.joins(:category)
                         .group('categories.name, categories.icon, categories.color')
                         .sum(:amount)
                         .map { |(name, icon, color), amt| { name: name, icon: icon, color: color, amount: amt } }
                         .sort_by { |c| -c[:amount] }

    render json: {
      status: 'success',
      data: {
        period: { start_date: start_date, end_date: end_date },
        total_income:   total_income,
        total_expenses: total_expenses,
        net:            net,
        savings_rate:   savings_rate,
        income_by_category:  income_by_cat,
        expense_by_category: expense_by_cat
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
