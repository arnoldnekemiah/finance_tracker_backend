class SavingGoal < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :current_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :target_date, presence: true

  scope :achieved, -> { where('current_amount >= target_amount') }
  scope :in_progress, -> { where('current_amount < target_amount') }
  scope :upcoming_deadline, -> { where('target_date <= ?', 30.days.from_now) }
  scope :overdue, -> { where('target_date < ? AND current_amount < target_amount', Date.current) }

  def progress_percentage
    return 100 if target_amount.zero?
    ((current_amount / target_amount) * 100).round(2)
  end

  def remaining_amount
    [target_amount - current_amount, 0].max
  end

  def achieved?
    current_amount >= target_amount
  end

  def days_remaining
    return 0 if target_date < Date.current
    (target_date.to_date - Date.today).to_i
  end

  def overdue?
    target_date < Date.current && !achieved?
  end

  def monthly_savings_needed
    return 0 if achieved? || days_remaining <= 0
    months_remaining = (days_remaining / 30.0).ceil
    remaining_amount / months_remaining
  end

  def add_progress(amount)
    self.current_amount += amount
    save
  end
end
