class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :from_account, class_name: 'Account', optional: true
  belongs_to :to_account, class_name: 'Account', optional: true
  belongs_to :account, optional: true # Legacy field for backward compatibility

  # Money gem integration
  monetize :original_amount_cents, as: :original_amount, with_model_currency: :original_currency

  scope :income, -> { where(transaction_type: 'income') }
  scope :expense, -> { where(transaction_type: 'expense') }
  scope :transfer, -> { where(transaction_type: 'transfer') }
  scope :this_month, -> { where(date: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :last_month, -> { where(date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }

  validates :transaction_type, presence: true, inclusion: { in: %w[income expense transfer] }
  validates :date, presence: true
  
  # Conditional validations based on transaction type
  validates :category_id, presence: true, if: -> { %w[income expense].include?(transaction_type) }
  validates :to_account_id, presence: true, if: -> { %w[income transfer].include?(transaction_type) }
  validates :from_account_id, presence: true, if: -> { %w[expense transfer].include?(transaction_type) }
  validates :from_account_id, :to_account_id, presence: true, if: -> { transaction_type == 'transfer' }
  validate :different_accounts_for_transfer, if: -> { transaction_type == 'transfer' }
  validates :original_currency, inclusion: { in: -> { CurrencyService.supported_currencies.keys } }

  private

  def user_currency
    user.effective_currency
  end
  
  def different_accounts_for_transfer
    if transaction_type == 'transfer' && from_account_id == to_account_id
      errors.add(:to_account_id, "cannot be the same as from_account for transfers")
    end
  end

  def formatted_amount
    CurrencyService.format_money(original_amount, user_currency)
  end

  def formatted_original_amount
    CurrencyService.format_money(original_amount_cents / 100.0, original_currency)
  end
end
