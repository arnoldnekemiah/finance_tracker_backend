class Debt < ApplicationRecord
  belongs_to :user

  monetize :original_amount_cents, as: :amount, with_model_currency: :original_currency

  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :creditor, presence: true
  validates :due_date, presence: true
  validates :status, inclusion: { in: %w[pending paid overdue] }
  validates :debt_type, inclusion: { in: %w[loan credit_card mortgage personal business] }

  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :overdue, -> { where(status: 'overdue') }
  scope :due_soon, -> { where('due_date <= ? AND status = ?', 7.days.from_now, 'pending') }

  def overdue?
    due_date < Date.current && status == 'pending'
  end

  def days_until_due
    (due_date - Date.current).to_i
  end
end
