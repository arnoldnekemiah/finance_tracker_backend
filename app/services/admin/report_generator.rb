class Admin::ReportGenerator
  include ActiveModel::Model

  def self.generate_daily_report
    new.generate_daily_report
  end

  def self.generate_weekly_report
    new.generate_weekly_report
  end

  def self.generate_monthly_report
    new.generate_monthly_report
  end

  def generate_daily_report
    date = Date.current
    
    report_data = {
      report_type: 'daily',
      date: date,
      generated_at: Time.current,
      metrics: {
        new_users: User.where(created_at: date.beginning_of_day..date.end_of_day).count,
        active_users: UserAnalytics.where(
          event_type: 'login',
          created_at: date.beginning_of_day..date.end_of_day
        ).distinct.count(:user_id),
        transactions_created: Transaction.where(created_at: date.beginning_of_day..date.end_of_day).count,
        total_transaction_volume: Transaction.where(created_at: date.beginning_of_day..date.end_of_day).sum(:amount),
        budgets_created: Budget.where(created_at: date.beginning_of_day..date.end_of_day).count,
        accounts_created: Account.where(created_at: date.beginning_of_day..date.end_of_day).count
      },
      top_activities: top_user_activities(date.beginning_of_day, date.end_of_day),
      system_health: system_health_check
    }

    save_report(report_data)
  end

  def generate_weekly_report
    end_date = Date.current
    start_date = end_date - 6.days
    
    report_data = {
      report_type: 'weekly',
      start_date: start_date,
      end_date: end_date,
      generated_at: Time.current,
      metrics: {
        new_users: User.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count,
        active_users: UserAnalytics.where(
          event_type: 'login',
          created_at: start_date.beginning_of_day..end_date.end_of_day
        ).distinct.count(:user_id),
        transactions_created: Transaction.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count,
        total_transaction_volume: Transaction.where(created_at: start_date.beginning_of_day..end_date.end_of_day).sum(:amount),
        user_growth_rate: calculate_growth_rate(start_date, end_date, 'users'),
        transaction_growth_rate: calculate_growth_rate(start_date, end_date, 'transactions')
      },
      daily_breakdown: daily_breakdown(start_date, end_date),
      top_users: top_active_users(start_date.beginning_of_day, end_date.end_of_day),
      category_analysis: category_analysis(start_date.beginning_of_day, end_date.end_of_day)
    }

    save_report(report_data)
  end

  def generate_monthly_report
    end_date = Date.current
    start_date = end_date.beginning_of_month
    
    report_data = {
      report_type: 'monthly',
      start_date: start_date,
      end_date: end_date,
      generated_at: Time.current,
      metrics: UserAnalytics.user_growth_metrics(start_date.beginning_of_day, end_date.end_of_day),
      transaction_metrics: UserAnalytics.transaction_volume_metrics(start_date.beginning_of_day, end_date.end_of_day),
      financial_insights: UserAnalytics.financial_insights(start_date.beginning_of_day, end_date.end_of_day),
      user_retention: calculate_user_retention(start_date, end_date),
      revenue_insights: revenue_analysis(start_date.beginning_of_day, end_date.end_of_day),
      weekly_breakdown: weekly_breakdown(start_date, end_date)
    }

    save_report(report_data)
  end

  def generate_custom_report(start_date, end_date, report_type = 'custom')
    report_data = {
      report_type: report_type,
      start_date: start_date,
      end_date: end_date,
      generated_at: Time.current,
      metrics: UserAnalytics.user_growth_metrics(start_date, end_date),
      transaction_metrics: UserAnalytics.transaction_volume_metrics(start_date, end_date),
      financial_insights: UserAnalytics.financial_insights(start_date, end_date),
      detailed_breakdown: detailed_breakdown(start_date, end_date)
    }

    save_report(report_data)
  end

  private

  def top_user_activities(start_time, end_time)
    UserAnalytics.where(created_at: start_time..end_time)
                 .group(:event_type)
                 .count
                 .sort_by { |_, count| -count }
                 .first(5)
                 .to_h
  end

  def top_active_users(start_time, end_time)
    UserAnalytics.joins(:user)
                 .where(created_at: start_time..end_time)
                 .group(:user_id)
                 .count
                 .sort_by { |_, count| -count }
                 .first(10)
                 .map do |user_id, activity_count|
      user = User.find(user_id)
      {
        user_id: user.id,
        email: user.email,
        full_name: user.full_name,
        activity_count: activity_count
      }
    end
  end

  def calculate_growth_rate(start_date, end_date, metric_type)
    current_period = case metric_type
                    when 'users'
                      User.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count
                    when 'transactions'
                      Transaction.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count
                    end

    previous_start = start_date - (end_date - start_date).days
    previous_end = start_date - 1.day

    previous_period = case metric_type
                     when 'users'
                       User.where(created_at: previous_start.beginning_of_day..previous_end.end_of_day).count
                     when 'transactions'
                       Transaction.where(created_at: previous_start.beginning_of_day..previous_end.end_of_day).count
                     end

    return 0 if previous_period == 0
    ((current_period - previous_period).to_f / previous_period * 100).round(2)
  end

  def daily_breakdown(start_date, end_date)
    (start_date..end_date).map do |date|
      {
        date: date,
        new_users: User.where(created_at: date.beginning_of_day..date.end_of_day).count,
        transactions: Transaction.where(created_at: date.beginning_of_day..date.end_of_day).count,
        transaction_volume: Transaction.where(created_at: date.beginning_of_day..date.end_of_day).sum(:amount)
      }
    end
  end

  def weekly_breakdown(start_date, end_date)
    weeks = []
    current_date = start_date.beginning_of_week
    
    while current_date <= end_date
      week_end = [current_date.end_of_week, end_date].min
      weeks << {
        week_start: current_date,
        week_end: week_end,
        new_users: User.where(created_at: current_date.beginning_of_day..week_end.end_of_day).count,
        transactions: Transaction.where(created_at: current_date.beginning_of_day..week_end.end_of_day).count,
        transaction_volume: Transaction.where(created_at: current_date.beginning_of_day..week_end.end_of_day).sum(:amount)
      }
      current_date += 1.week
    end
    
    weeks
  end

  def category_analysis(start_time, end_time)
    Transaction.joins(:category)
               .where(created_at: start_time..end_time)
               .group('categories.name')
               .group("DATE(created_at)")
               .sum(:amount)
  end

  def calculate_user_retention(start_date, end_date)
    new_users = User.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    
    return 0 if new_users.count == 0
    
    retained_users = new_users.joins(:user_analytics)
                              .where(user_analytics: { 
                                event_type: 'login',
                                created_at: (end_date + 1.day).beginning_of_day..(end_date + 7.days).end_of_day
                              })
                              .distinct
                              .count

    (retained_users.to_f / new_users.count * 100).round(2)
  end

  def revenue_analysis(start_time, end_time)
    # Placeholder for revenue analysis - would be more relevant with premium features
    {
      total_revenue: 0,
      average_revenue_per_user: 0,
      revenue_growth: 0
    }
  end

  def detailed_breakdown(start_date, end_date)
    {
      user_demographics: user_demographics(start_date, end_date),
      transaction_patterns: transaction_patterns(start_date, end_date),
      feature_usage: feature_usage(start_date, end_date)
    }
  end

  def user_demographics(start_date, end_date)
    users = User.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    
    {
      total_users: users.count,
      currency_breakdown: users.group(:currency).count,
      admin_users: users.where(admin: true).count
    }
  end

  def transaction_patterns(start_date, end_date)
    transactions = Transaction.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    
    {
      total_transactions: transactions.count,
      income_transactions: transactions.where('amount > 0').count,
      expense_transactions: transactions.where('amount < 0').count,
      average_transaction_amount: transactions.average(:amount)&.round(2) || 0
    }
  end

  def feature_usage(start_date, end_date)
    UserAnalytics.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                 .group(:event_type)
                 .count
  end

  def system_health_check
    {
      database_status: 'healthy',
      total_users: User.count,
      total_transactions: Transaction.count,
      memory_usage: `ps -o rss= -p #{Process.pid}`.to_i,
      timestamp: Time.current
    }
  rescue => e
    {
      database_status: 'error',
      error_message: e.message,
      timestamp: Time.current
    }
  end

  def save_report(report_data)
    # In a real application, you might save this to a database table or file system
    # For now, we'll just return the report data
    Rails.logger.info "Generated #{report_data[:report_type]} report: #{report_data.to_json}"
    report_data
  end
end
