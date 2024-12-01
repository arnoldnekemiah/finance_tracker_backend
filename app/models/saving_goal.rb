class SavingGoal < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :current_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :target_date, presence: true
  validate :target_date_cannot_be_in_past

  scope :achieved, -> { where('current_amount >= target_amount') }
  scope :in_progress, -> { where('current_amount < target_amount') }
  scope :upcoming_deadline, -> { where('target_date <= ?', 30.days.from_now) }

  private

  def target_date_cannot_be_in_past
    if target_date.present? && target_date < Date.today
      errors.add(:target_date, "can't be in the past")
    end
  end
end
