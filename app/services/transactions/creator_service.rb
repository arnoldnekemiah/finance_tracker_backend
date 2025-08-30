class Transactions::CreatorService
  def initialize(user, params)
    @user = user
    @params = params.dup
  end

  def call
    # Get the transaction parameters
    transaction_params = if @params.is_a?(ActionController::Parameters)
      @params.require(:transaction).permit(
        :amount, :description, :transaction_type, :date, :notes,
        :payment_method, :category_id, :from_account_id, :to_account_id, :account_id
      ).to_h.symbolize_keys
    else
      (@params[:transaction] || @params).to_unsafe_h.symbolize_keys
    end
    
    # Prepare the attributes for the transaction
    attributes = {
      description: transaction_params[:description],
      transaction_type: transaction_params[:transaction_type],
      date: transaction_params[:date],
      notes: transaction_params[:notes],
      payment_method: transaction_params[:payment_method],
      category_id: transaction_params[:category_id],
      from_account_id: transaction_params[:from_account_id],
      to_account_id: transaction_params[:to_account_id],
      account_id: transaction_params[:account_id],
      original_currency: 'USD',
      user: @user
    }
    
    # Convert amount to cents if present
    if transaction_params[:amount].present?
      attributes[:original_amount_cents] = (transaction_params[:amount].to_f * 100).to_i
    end
    
    # Remove nil values
    attributes.compact!
    
    transaction = Transaction.new(attributes)
    
    if transaction.save
      update_account_balances(transaction) if transaction.persisted?
      success(transaction)
    else
      failure(transaction.errors)
    end
  end

  private

  def success(transaction)
    { success: true, transaction: transaction }
  end

  def failure(errors)
    { success: false, errors: errors }
  end

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
