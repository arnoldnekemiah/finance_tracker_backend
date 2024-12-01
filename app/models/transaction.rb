class Transaction < ApplicationRecord
  belongs_to :user
  
  scope :income, -> { where(type: 'income') }
  scope :expense, -> { where(type: 'expense') }
  scope :this_month, -> { where(date: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :last_month, -> { where(date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true
  validates :type, presence: true, inclusion: { in: %w[income expense] }
  validates :date, presence: true
end
