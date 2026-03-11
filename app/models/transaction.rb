class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account, optional: true
  belongs_to :category, optional: true
  belongs_to :from_account, class_name: 'Account', optional: true
  belongs_to :to_account, class_name: 'Account', optional: true

  scope :income, -> { where(transaction_type: 'income') }
  scope :expense, -> { where(transaction_type: 'expense') }
  scope :transfer, -> { where(transaction_type: 'transfer') }
  scope :this_month, -> { where(date: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :last_month, -> { where(date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :original_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense transfer] }
  validates :date, presence: true

  # Conditional validations based on transaction type
  validates :category_id, presence: true, if: -> { %w[income expense].include?(transaction_type) }
  validates :from_account_id, presence: true, if: -> { transaction_type == 'transfer' }
  validates :to_account_id, presence: true, if: -> { transaction_type == 'transfer' }
  validate :different_accounts_for_transfer, if: -> { transaction_type == 'transfer' }

  before_save :set_defaults
  after_create  :apply_balance_effect
  after_update  :rebalance_accounts
  before_destroy :revert_balance_effect
  after_save    :sync_affected_budgets
  after_destroy :sync_affected_budgets

  private

  def set_defaults
    self.original_amount ||= amount if amount.present?
    self.original_currency ||= user&.effective_currency || 'USD'
    self.category_name ||= category&.name
  end

  def different_accounts_for_transfer
    if transaction_type == 'transfer' && from_account_id == to_account_id
      errors.add(:to_account_id, "cannot be the same as from_account for transfers")
    end
  end

  # ── Balance helpers ───────────────────────────────────────────────────────

  def apply_balance_effect(txn_type: transaction_type, acct_id: account_id,
                            from_id: from_account_id, to_id: to_account_id, amt: amount)
    return unless amt.present? && amt > 0

    case txn_type
    when 'income'
      Account.find_by(id: acct_id)&.increment!(:balance, amt)
    when 'expense'
      Account.find_by(id: acct_id)&.decrement!(:balance, amt)
    when 'transfer'
      Account.find_by(id: from_id)&.decrement!(:balance, amt)
      Account.find_by(id: to_id)&.increment!(:balance, amt)
    end
  end

  def revert_balance_effect(txn_type: transaction_type, acct_id: account_id,
                             from_id: from_account_id, to_id: to_account_id, amt: amount)
    return unless amt.present? && amt > 0

    case txn_type
    when 'income'
      Account.find_by(id: acct_id)&.decrement!(:balance, amt)
    when 'expense'
      Account.find_by(id: acct_id)&.increment!(:balance, amt)
    when 'transfer'
      Account.find_by(id: from_id)&.increment!(:balance, amt)
      Account.find_by(id: to_id)&.decrement!(:balance, amt)
    end
  end

  def rebalance_accounts
    relevant_changes = %w[amount transaction_type account_id from_account_id to_account_id]
    return unless relevant_changes.any? { |attr| saved_change_to_attribute?(attr) }

    old_type   = transaction_type_before_last_save || transaction_type
    old_amount = (amount_before_last_save || amount).to_d
    old_acct   = account_id_before_last_save || account_id
    old_from   = from_account_id_before_last_save || from_account_id
    old_to     = to_account_id_before_last_save || to_account_id

    revert_balance_effect(txn_type: old_type, acct_id: old_acct,
                          from_id: old_from, to_id: old_to, amt: old_amount)
    apply_balance_effect
  end

  # ── Budget sync ───────────────────────────────────────────────────────────

  def sync_affected_budgets
    return unless %w[income expense].include?(transaction_type)

    user.budgets
        .where(category_id: category_id)
        .where('start_date <= ? AND end_date >= ?', date, date)
        .each(&:update_spent_amount!)
  end
end
