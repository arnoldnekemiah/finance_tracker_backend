class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :account, optional: true

  # Money gem integration
  monetize :original_amount_cents, as: :original_amount, with_model_currency: :original_currency
  monetize :amount_cents, as: :amount_money, with_model_currency: :user_currency

  scope :income, -> { where(transaction_type: 'income') }
  scope :expense, -> { where(transaction_type: 'expense') }
  scope :this_month, -> { where(date: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :last_month, -> { where(date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :category_id, presence: true
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense] }
  validates :date, presence: true
  validates :original_currency, inclusion: { in: -> { CurrencyService.supported_currencies.keys } }

  before_save :set_original_amount_and_currency
  before_save :convert_to_user_currency

  private

  def set_original_amount_and_currency
    if original_amount_cents.blank? && amount.present?
      self.original_amount_cents = (amount * 100).to_i
    end
    
    if original_currency.blank?
      self.original_currency = user.effective_currency
    end
  end

  def convert_to_user_currency
    user_curr = user.effective_currency
    
    if original_currency != user_curr
      self.exchange_rate = CurrencyService.get_exchange_rate(original_currency, user_curr)
      converted_amount = CurrencyService.convert_amount(original_amount_cents / 100.0, original_currency, user_curr)
      self.amount = converted_amount
    else
      self.amount = original_amount_cents / 100.0 if original_amount_cents.present?
      self.exchange_rate = 1.0
    end
  end

  def user_currency
    user.effective_currency
  end

  def formatted_amount
    CurrencyService.format_money(amount, user_currency)
  end

  def formatted_original_amount
    CurrencyService.format_money(original_amount_cents / 100.0, original_currency)
  end
end
