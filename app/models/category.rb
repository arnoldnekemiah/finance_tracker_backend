class Category < ApplicationRecord
  belongs_to :user
  has_many :transactions
  has_many :budgets

  validates :name, presence: true
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense] }
end
