class Transactions::DestroyerService
  def initialize(transaction)
    @transaction = transaction
  end

  def call
    # Store state before destroying
    transaction_type = @transaction.transaction_type
    from_account = @transaction.from_account
    to_account = @transaction.to_account
    amount = @transaction.original_amount

    if @transaction.destroy
      revert_account_balances(transaction_type, from_account, to_account, amount)
      { success: true }
    else
      { success: false, errors: @transaction.errors }
    end
  end

  private

  def revert_account_balances(transaction_type, from_account, to_account, amount)
    case transaction_type
    when 'income'
      update_balance(to_account, -amount)
    when 'expense'
      update_balance(from_account, amount)
    when 'transfer'
      update_balance(from_account, amount)
      update_balance(to_account, -amount)
    end
  end

  def update_balance(account, amount)
    return unless account && amount.is_a?(Money)

    account.balance += amount
    account.save!
  end
end
