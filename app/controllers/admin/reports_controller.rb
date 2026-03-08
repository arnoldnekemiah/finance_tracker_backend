class Admin::ReportsController < Admin::BaseController

  def index
    # Reports index page
  end

  def generate_daily
    report = generate_report('daily', Date.yesterday, Date.current)
    render json: { message: 'Daily report generated', report: report }
  end

  def generate_weekly
    report = generate_report('weekly', 1.week.ago.to_date, Date.current)
    render json: { message: 'Weekly report generated', report: report }
  end

  def generate_monthly
    report = generate_report('monthly', 1.month.ago.to_date, Date.current)
    render json: { message: 'Monthly report generated', report: report }
  end

  def generate_custom
    start_date = parse_date(params[:start_date])
    end_date = parse_date(params[:end_date])

    if start_date.nil? || end_date.nil?
      return render json: { error: 'Invalid date parameters' }, status: :bad_request
    end
    if start_date > end_date
      return render json: { error: 'Start date cannot be after end date' }, status: :bad_request
    end

    report = generate_report('custom', start_date, end_date)
    render json: { message: 'Custom report generated', report: report }
  end

  def schedule_reports
    render json: {
      message: 'Report scheduling configured',
      schedule: {
        daily: { enabled: true, time: '06:00 UTC' },
        weekly: { enabled: true, day: 'Monday', time: '07:00 UTC' },
        monthly: { enabled: true, day: 1, time: '08:00 UTC' }
      }
    }
  end

  private

  def generate_report(type, start_date, end_date)
    transactions = Transaction.where(date: start_date..end_date)
    users = User.where(created_at: start_date.beginning_of_day..end_date.end_of_day)

    {
      type: type,
      period: { start: start_date, end: end_date },
      users: { new: users.count, total: User.count },
      transactions: {
        count: transactions.count,
        total_income: transactions.income.sum(:amount),
        total_expenses: transactions.expense.sum(:amount)
      }
    }
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end
end
