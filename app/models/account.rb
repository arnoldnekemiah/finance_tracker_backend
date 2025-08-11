class Account < ApplicationRecord
  belongs_to :user
  has_many :transactions

  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: %w[regular debt savings] }
  validates :balance, presence: true, numericality: true
  validates :currency, presence: true

  scope :active, -> { where(is_active: true) }
  scope :asset_accounts, -> { where(account_type: %w[regular savings]) }
  scope :debt_accounts, -> { where(account_type: 'debt') }
  scope :regular_accounts, -> { where(account_type: 'regular') }
  scope :savings_accounts, -> { where(account_type: 'savings') }

  def formatted_balance
    "#{currency} #{balance.to_f}"
  end

  def account_number_masked
    return nil unless account_number.present?
    "****#{account_number.last(4)}"
  end
end
