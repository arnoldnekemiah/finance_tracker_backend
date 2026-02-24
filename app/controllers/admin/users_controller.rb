class Admin::UsersController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!
  before_action :set_user, only: [:show, :update, :destroy, :activate, :deactivate, :make_admin, :remove_admin]

  rescue_from StandardError, with: :handle_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  def index
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    offset = (page - 1) * per_page

    base_query = User.includes(:transactions, :budgets, :accounts)
    base_query = base_query.where('email ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    base_query = base_query.where(is_admin: params[:is_admin]) if params[:is_admin].present?

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
    @user.destroy
    render json: { message: 'User deleted successfully' }
  end

  def activate
    @user.update!(is_active: true)
    render json: { message: 'User activated', user: user_summary(@user) }
  end

  def deactivate
    if @user.admin?
      return render json: { error: 'Cannot deactivate admin users' }, status: :forbidden
    end
    @user.update!(is_active: false)
    render json: { message: 'User deactivated', user: user_summary(@user) }
  end

  def make_admin
    @user.make_admin!
    render json: { message: 'Admin privileges granted', user: user_summary(@user) }
  end

  def remove_admin
    if User.admins.count <= 1
      return render json: { error: 'Cannot remove the last admin' }, status: :forbidden
    end
    @user.remove_admin!
    render json: { message: 'Admin privileges removed', user: user_summary(@user) }
  end

  private

  def authenticate_admin_user!
    unless current_user&.admin?
      redirect_to admin_login_path, alert: 'Admin access required'
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :currency, :is_active)
  end

  def user_summary(user)
    {
      id: user.id, email: user.email, full_name: user.full_name,
      first_name: user.first_name, last_name: user.last_name,
      currency: user.currency, is_admin: user.admin?, is_active: user.is_active,
      provider: user.provider, created_at: user.created_at,
      transactions_count: user.transactions.size, accounts_count: user.accounts.size
    }
  end

  def detailed_user_info(user)
    user_summary(user).merge(
      total_transaction_amount: user.transactions.sum(:amount),
      active_budgets: user.budgets.where('end_date > ?', Date.current).count,
      total_debt: user.debts.sum(:amount),
      saving_goals_count: user.saving_goals.count
    )
  end

  def user_financial_summary(user)
    {
      total_income: user.transactions.income.sum(:amount),
      total_expenses: user.transactions.expense.sum(:amount),
      active_accounts: user.accounts.active.count
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
