class Transactions::UpdaterService
  def initialize(transaction, params)
    @transaction = transaction
    @params = params
  end

  def call
    # Store old state
    old_type = @transaction.transaction_type
    old_from_account = @transaction.from_account
    old_to_account = @transaction.to_account
    old_amount = @transaction.original_amount

    if @transaction.update(@params)
      revert_account_balances(old_type, old_from_account, old_to_account, old_amount)
      update_account_balances(@transaction)
      { success: true, transaction: @transaction }
    else
      { success: false, errors: @transaction.errors }
    end
  end

  private

  def update_account_balances(transaction)
    case transaction.transaction_type
    when 'income'
      update_balance(transaction.to_account, transaction.original_amount)
    when 'expense'
      update_balance(transaction.from_account, -transaction.original_amount)
    when 'transfer'
      update_balance(transaction.from_account, -transaction.original_amount)
      update_balance(transaction.to_account, transaction.original_amount)
    end
  end

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
