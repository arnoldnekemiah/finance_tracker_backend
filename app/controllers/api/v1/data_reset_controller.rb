class Api::V1::DataResetController < Api::BaseController
  include Authenticatable

  # POST /api/v1/data/start_afresh
  # Deletes all user data except the user account itself
  def start_afresh
    ActiveRecord::Base.transaction do
      current_user.transactions.destroy_all
      current_user.budgets.destroy_all
      current_user.debts.destroy_all
      current_user.saving_goals.destroy_all
      current_user.support_messages.destroy_all
      current_user.accounts.update_all(balance: 0.0)
    end

    render json: {
      status: 'success',
      data: { message: 'All financial data has been reset. Your account and categories are preserved.' }
    }
  end

  # POST /api/v1/data/delete_all
  # Deletes ALL user data including categories and accounts
  def delete_all
    ActiveRecord::Base.transaction do
      current_user.transactions.destroy_all
      current_user.budgets.destroy_all
      current_user.debts.destroy_all
      current_user.saving_goals.destroy_all
      current_user.support_messages.destroy_all
      current_user.categories.destroy_all
      current_user.accounts.destroy_all
    end

    render json: {
      status: 'success',
      data: { message: 'All data has been deleted.' }
    }
  end

  # POST /api/v1/data/reset_balances
  # Resets all account balances to 0
  def reset_balances
    current_user.accounts.update_all(balance: 0.0)

    render json: {
      status: 'success',
      data: { message: 'All account balances have been reset to 0.' }
    }
  end

  # POST /api/v1/data/reconcile_balances
  # Recomputes account balances from all transactions
  def reconcile_balances
    ActiveRecord::Base.transaction do
      current_user.accounts.update_all(balance: 0.0)

      # Income: add to account
      current_user.transactions.income.where.not(account_id: nil).each do |t|
        Account.find_by(id: t.account_id)&.increment!(:balance, t.amount)
      end

      # Expense: subtract from account
      current_user.transactions.expense.where.not(account_id: nil).each do |t|
        Account.find_by(id: t.account_id)&.decrement!(:balance, t.amount)
      end

      # Transfer: debit from_account, credit to_account
      current_user.transactions.transfer.each do |t|
        Account.find_by(id: t.from_account_id)&.decrement!(:balance, t.amount)
        Account.find_by(id: t.to_account_id)&.increment!(:balance, t.amount)
      end
    end

    render json: {
      status: 'success',
      data: {
        message: 'Account balances have been reconciled from transaction history.',
        accounts: current_user.accounts.active.map { |a| { id: a.id, name: a.name, balance: a.balance.to_f, currency: a.currency } }
      }
    }
  end
end
