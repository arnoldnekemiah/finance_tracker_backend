class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :limit, presence: true, numericality: { greater_than: 0 }
  validates :spent, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :period, presence: true, inclusion: { in: %w[weekly monthly quarterly yearly] }
  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :active, -> { where('end_date >= ?', Date.current) }
  scope :expired, -> { where('end_date < ?', Date.current) }
  scope :over_budget, -> { where('spent > limit') }
  scope :by_period, ->(period) { where(period: period) }

  def percentage_used
    return 0 if limit.zero?
    ((spent / limit) * 100).round(2)
  end

  def remaining_amount
    [limit - spent, 0].max
  end

  def over_budget?
    spent > limit
  end

  def days_remaining
    return 0 if end_date < Date.current
    (end_date - Date.current).to_i
  end

  def update_spent_amount!
    total_spent = user.transactions
                     .expense
                     .where(category: category)
                     .where(date: start_date..end_date)
                     .sum(:amount)
    update!(spent: total_spent)
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    
    errors.add(:end_date, 'must be after start date') if end_date <= start_date
  end
end
