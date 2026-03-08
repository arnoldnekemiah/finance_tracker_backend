class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :update, :destroy, :activate, :deactivate, :make_admin, :remove_admin]

  rescue_from StandardError, with: :handle_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  def index
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    offset = (page - 1) * per_page

    base_query = User.includes(:transactions, :budgets, :accounts, :debts, :saving_goals, :categories)
    base_query = base_query.where('email ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    base_query = base_query.where(admin: params[:is_admin]) if params[:is_admin].present?

    @total_count = base_query.count
    @users = base_query.order(created_at: :desc).limit(per_page).offset(offset)
    @current_page = page
    @per_page = per_page
    @offset = offset

    respond_to do |format|
      format.html
      format.json {
        render json: {
          users: @users.map { |u| user_summary(u) },
          pagination: { current_page: page, total_count: @total_count, per_page: per_page }
        }
      }
    end
  end

  def show
    render json: {
      user: detailed_user_info(@user),
      financial_summary: user_financial_summary(@user)
    }
  end

  def update
    if @user.update(user_params)
      render json: { message: 'User updated successfully', user: user_summary(@user) }
    else
      render json: { error: @user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.admin? && User.admins.count <= 1
      return render json: { error: 'Cannot delete the last admin user' }, status: :forbidden
    end
    log_admin_action('user_deleted', resource: @user, details: "Deleted user #{@user.email}")
    @user.destroy
    render json: { message: 'User deleted successfully' }
  end

  def activate
    @user.update!(active: true)
    log_admin_action('user_activated', resource: @user)
    render json: { message: 'User activated', user: user_summary(@user) }
  end

  def deactivate
    if @user.admin?
      return render json: { error: 'Cannot deactivate admin users' }, status: :forbidden
    end
    @user.update!(active: false)
    log_admin_action('user_deactivated', resource: @user)
    render json: { message: 'User deactivated', user: user_summary(@user) }
  end

  def make_admin
    @user.make_admin!
    log_admin_action('admin_granted', resource: @user)
    render json: { message: 'Admin privileges granted', user: user_summary(@user) }
  end

  def remove_admin
    if User.admins.count <= 1
      return render json: { error: 'Cannot remove the last admin' }, status: :forbidden
    end
    @user.remove_admin!
    log_admin_action('admin_revoked', resource: @user)
    render json: { message: 'Admin privileges removed', user: user_summary(@user) }
  end

  private

  def set_user
    @user = User.includes(:transactions, :budgets, :accounts, :debts, :saving_goals, :categories).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :currency, :active)
  end

  def user_summary(user)
    {
      id:                  user.id,
      email:               user.email,
      full_name:           user.full_name,
      first_name:          user.first_name,
      last_name:           user.last_name,
      currency:            user.currency,
      is_admin:            user.admin?,
      is_active:           user.is_active,
      provider:            user.provider,
      created_at:          user.created_at,
      transactions_count:  user.transactions.size,
      accounts_count:      user.accounts.size
    }
  end

  def detailed_user_info(user)
    pending_debt_amount = user.debts.where(status: 'pending').sum(:amount).to_f.round(2)
    overdue_debt_amount = user.debts.where(status: 'overdue').sum(:amount).to_f.round(2)
    paid_debt_amount    = user.debts.where(status: 'paid').sum(:amount).to_f.round(2)

    active_budgets      = user.budgets.where('start_date <= ? AND end_date >= ?', Date.current, Date.current)
    total_budget_limit  = active_budgets.sum(:limit).to_f
    total_budget_spent  = active_budgets.sum(:spent).to_f

    saving_goals        = user.saving_goals
    goals_achieved      = saving_goals.where('current_amount >= target_amount').count
    goals_in_progress   = saving_goals.where('current_amount < target_amount').count
    total_saved         = saving_goals.sum(:current_amount).to_f.round(2)
    total_goal_target   = saving_goals.sum(:target_amount).to_f.round(2)

    user_summary(user).merge(
      # Transaction totals
      total_transaction_amount:   user.transactions.sum(:amount).to_f.round(2),
      total_income:               user.transactions.income.sum(:amount).to_f.round(2),
      total_expenses:             user.transactions.expense.sum(:amount).to_f.round(2),
      net_income:                 (user.transactions.income.sum(:amount) - user.transactions.expense.sum(:amount)).to_f.round(2),
      transactions_this_month:    user.transactions.this_month.count,

      # Accounts
      active_accounts:            user.accounts.active.count,
      total_account_balance:      user.accounts.active.sum(:balance).to_f.round(2),
      asset_account_balance:      user.accounts.active.asset_accounts.sum(:balance).to_f.round(2),

      # Budgets
      active_budgets_count:       active_budgets.count,
      categories_count:           user.categories.count,
      budget_utilization: {
        total_limit:         total_budget_limit,
        total_spent:         total_budget_spent,
        utilization_percent: total_budget_limit > 0 ? ((total_budget_spent / total_budget_limit) * 100).round(1) : 0,
        over_budget_count:   active_budgets.where('spent > limit').count
      },

      # Debts
      total_debts:          user.debts.count,
      debt_breakdown: {
        pending_count:  user.debts.where(status: 'pending').count,
        overdue_count:  user.debts.where(status: 'overdue').count,
        paid_count:     user.debts.where(status: 'paid').count,
        pending_amount: pending_debt_amount,
        overdue_amount: overdue_debt_amount,
        paid_amount:    paid_debt_amount,
        total_outstanding: (pending_debt_amount + overdue_debt_amount).round(2)
      },

      # Saving Goals
      saving_goals_count: saving_goals.count,
      saving_goals_summary: {
        achieved:          goals_achieved,
        in_progress:       goals_in_progress,
        total_saved:       total_saved,
        total_target:      total_goal_target,
        overall_progress:  total_goal_target > 0 ? ((total_saved / total_goal_target) * 100).round(1) : 0
      }
    )
  end

  def user_financial_summary(user)
    {
      total_income:               user.transactions.income.sum(:amount).to_f.round(2),
      total_expenses:             user.transactions.expense.sum(:amount).to_f.round(2),
      net_income:                 (user.transactions.income.sum(:amount) - user.transactions.expense.sum(:amount)).to_f.round(2),
      active_accounts:            user.accounts.active.count,
      total_balance:              user.accounts.active.sum(:balance).to_f.round(2),
      total_outstanding_debt:     user.debts.where(status: %w[pending overdue]).sum(:amount).to_f.round(2),
      saving_goals_progress:      user.saving_goals.count > 0 ? {
        total:   user.saving_goals.count,
        achieved: user.saving_goals.where('current_amount >= target_amount').count,
        saved:   user.saving_goals.sum(:current_amount).to_f.round(2),
        target:  user.saving_goals.sum(:target_amount).to_f.round(2)
      } : nil,
      recent_transactions:        user.transactions
                                      .includes(:category)
                                      .order(date: :desc)
                                      .limit(5)
                                      .map do |t|
                                        {
                                          id:       t.id,
                                          amount:   t.amount.to_f,
                                          type:     t.transaction_type,
                                          category: t.category&.name,
                                          date:     t.date
                                        }
                                      end
    }
  end

  def handle_error(e)
    Rails.logger.error "Admin Users Error: #{e.message}"
    flash[:alert] = "An error occurred."
    redirect_to admin_users_path
  end

  def handle_not_found(_)
    flash[:alert] = "User not found."
    redirect_to admin_users_path
  end
end
