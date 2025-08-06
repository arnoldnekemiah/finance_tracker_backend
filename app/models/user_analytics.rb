class UserAnalytics < ApplicationRecord
  belongs_to :user

  validates :event_type, presence: true
  validates :event_data, presence: true

  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Event types
  EVENT_TYPES = %w[
    login
    logout
    admin_login
    admin_logout
    registration
    transaction_created
    transaction_updated
    transaction_deleted
    budget_created
    budget_updated
    account_created
    saving_goal_created
    debt_created
    profile_updated
  ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }

  def self.track_event(user, event_type, event_data = {})
    create!(
      user: user,
      event_type: event_type,
      event_data: event_data.merge(
        timestamp: Time.current,
        ip_address: event_data[:ip_address],
        user_agent: event_data[:user_agent]
      )
    )
  end

  def self.user_growth_metrics(start_date = 30.days.ago, end_date = Time.current)
    {
      total_users: User.count,
      new_users_period: User.where(created_at: start_date..end_date).count,
      active_users_period: joins(:user).where(created_at: start_date..end_date, event_type: 'login').distinct.count('user_id'),
      registrations_by_day: User.where(created_at: start_date..end_date)
                                .group("DATE(created_at)")
                                .count
    }
  end

  def self.transaction_volume_metrics(start_date = 30.days.ago, end_date = Time.current)
    {
      total_transactions: Transaction.count,
      transactions_period: Transaction.where(created_at: start_date..end_date).count,
      transaction_volume: Transaction.where(created_at: start_date..end_date).sum(:amount),
      transactions_by_day: Transaction.where(created_at: start_date..end_date)
                                     .group("DATE(created_at)")
                                     .count,
      avg_transaction_amount: Transaction.where(created_at: start_date..end_date).average(:amount)
    }
  end

  def self.financial_insights(start_date = 30.days.ago, end_date = Time.current)
    {
      total_budgets: Budget.count,
      total_saving_goals: SavingGoal.count,
      total_debts: Debt.count,
      active_accounts: Account.count,
      budget_utilization: Budget.joins(:transactions)
                                .where(transactions: { created_at: start_date..end_date })
                                .group(:id)
                                .sum('transactions.amount'),
      debt_payments: where(event_type: 'debt_created', created_at: start_date..end_date).count
    }
  end
end
