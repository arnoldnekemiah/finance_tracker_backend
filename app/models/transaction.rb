class Transaction < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :account
  
  # Money configuration
  monetize :original_amount_cents, as: :original_amount, with_model_currency: :original_currency
  
  # Enums
  enum transaction_type: { income: 'income', expense: 'expense' }
  
  # Validations
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense], message: "must be either 'income' or 'expense'" }
  validates :original_amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :original_currency, presence: true
  validates :date, presence: true
  validates :account_id, presence: true
  
  # Scopes
  scope :incomes, -> { where(transaction_type: :income) }
  scope :expenses, -> { where(transaction_type: :expense) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :last_month, -> { where(date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }
  
  # Callbacks
  before_validation :set_default_currency
  
  # Instance Methods
  def formatted_original_amount
    return nil unless original_amount_cents.present?
    Money.new(original_amount_cents, original_currency).format
  end
  
  private
  
  def set_default_currency
    self.original_currency ||= 'USD'
  end
  
  def validate_account_ownership
    return unless account_id_changed?
    
    unless account.user_id == user_id
      errors.add(:base, 'You do not have permission to use this account')
    end
  end
end
