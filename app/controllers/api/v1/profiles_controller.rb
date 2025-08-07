class Api::V1::ProfilesController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_authorization_check

  def show
    render json: current_user, serializer: UserSerializer
  end

  def update
    if current_user.update(profile_params)
      render json: current_user, serializer: UserSerializer
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  def dashboard_summary
    summary = {
      user: UserSerializer.new(current_user).serializable_hash[:data][:attributes],
      accounts_summary: {
        total_accounts: current_user.accounts.active.count,
        total_balance: current_user.accounts.active.sum(:balance),
        account_types: current_user.accounts.active.group(:account_type).count
      },
      financial_overview: {
        total_income_this_month: current_user.transactions.income.this_month.sum(:amount),
        total_expenses_this_month: current_user.transactions.expense.this_month.sum(:amount),
        active_budgets: current_user.budgets.count,
        saving_goals: current_user.saving_goals.count,
        pending_debts: current_user.debts.pending.count,
        overdue_debts: current_user.debts.overdue.count
      }
    }
    
    render json: { data: summary }
  end

  private

  def profile_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :currency
    )
  end
end
