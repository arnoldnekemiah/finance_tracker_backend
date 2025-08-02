class Account < ApplicationRecord
  belongs_to :user
  has_many :transactions

  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: %w[bank mobile_money savings checking credit] }
  validates :balance, presence: true, numericality: true
  validates :currency, presence: true

  scope :active, -> { where(is_active: true) }
  scope :bank_accounts, -> { where(account_type: %w[bank savings checking]) }
  scope :mobile_money, -> { where(account_type: 'mobile_money') }

  def formatted_balance
    "#{currency} #{balance.to_f}"
  end

  def account_number_masked
    return nil unless account_number.present?
    "****#{account_number.last(4)}"
  end
end
