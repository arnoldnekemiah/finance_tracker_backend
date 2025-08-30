class SavingGoal < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :current_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :target_date, presence: true
  validate :target_date_cannot_be_in_past
  validate :current_amount_cannot_exceed_target

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
    return 0 unless target_date.is_a?(Date) || target_date.is_a?(Time)
    today = Date.current
    return 0 if target_date.to_date < today
    (target_date.to_date - today).to_i
  end

  def overdue?
    return false unless target_date.is_a?(Date) || target_date.is_a?(Time)
    target_date.to_date < Date.current && !achieved?
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

  private

  def target_date_cannot_be_in_past
    if target_date.present? && target_date < Date.today
      errors.add(:target_date, "can't be in the past")
    end
  end

  def current_amount_cannot_exceed_target
    if current_amount.present? && target_amount.present? && current_amount > target_amount
      errors.add(:current_amount, "cannot exceed target amount")
    end
  end
end
