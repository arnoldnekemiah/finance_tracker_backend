class Transactions::CreatorService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    transaction = @user.transactions.build(@params)
    if transaction.save
      update_account_balances(transaction)
      { success: true, transaction: transaction }
    else
      { success: false, errors: transaction.errors }
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

  def update_balance(account, amount)
    return unless account && amount.is_a?(Money)

    account.balance += amount
    account.save!
  end
end
