class Admin::UsersController < ApplicationController
  layout 'admin'
  skip_before_action :authenticate_user!
  before_action :authenticate_admin_user!
  before_action :ensure_admin_access
  before_action :set_user, only: [:show, :update, :destroy, :activate, :deactivate, :make_admin, :remove_admin]
  
  rescue_from StandardError, with: :handle_user_management_error
  rescue_from CanCan::AccessDenied, with: :handle_access_denied
  rescue_from ActiveRecord::RecordNotFound, with: :handle_user_not_found

  def index
    authorize! :manage, :user_management
    
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i
    offset = (page - 1) * per_page
    
    # Build base query with filters
    base_query = User.includes(:transactions, :budgets, :accounts)
    base_query = base_query.where('email ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    base_query = base_query.where(admin: params[:admin]) if params[:admin].present?
    base_query = base_query.where('created_at >= ?', params[:created_after]) if params[:created_after].present?
    
    # Get total count and paginated results
    @total_count = base_query.count
    @users = base_query.limit(per_page).offset(offset)
    
    # Pagination data
    @current_page = page
    @per_page = per_page
    @offset = offset

    respond_to do |format|
      format.html # Render the view
      format.json {
        render json: {
          users: @users.map { |user| user_summary(user) },
          pagination: {
            current_page: @users.current_page,
            total_pages: @users.total_pages,
            total_count: @users.total_count,
            per_page: @users.limit_value
          }
        }
      }
    end
  end

  def show
    authorize! :manage, :user_management
    
    render json: {
      user: detailed_user_info(@user),
      recent_activity: user_recent_activity(@user),
      financial_summary: user_financial_summary(@user)
    }
  end

  def update
    authorize! :manage, :user_management
    
    if @user.update(user_params)
      UserAnalytics.track_event(
        current_user,
        'admin_user_updated',
        {
          target_user_id: @user.id,
          updated_fields: user_params.keys,
          ip_address: request.remote_ip
        }
      )
      
      render json: {
        message: 'User updated successfully',
        user: user_summary(@user)
      }
    else
      render json: {
        error: 'Failed to update user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :manage, :user_management
    
    if @user.admin? && User.admins.count <= 1
      render json: {
        error: 'Cannot delete the last admin user'
      }, status: :forbidden
      return
    end

    UserAnalytics.track_event(
      current_user,
      'admin_user_deleted',
      {
        target_user_id: @user.id,
        target_user_email: @user.email,
        ip_address: request.remote_ip
      }
    )

    @user.destroy
    render json: { message: 'User deleted successfully' }
  end

  def activate
    authorize! :manage, :user_management
    
    # Assuming you have an active field or similar
    @user.update(active: true)
    
    UserAnalytics.track_event(
      current_user,
      'admin_user_activated',
      {
        target_user_id: @user.id,
        ip_address: request.remote_ip
      }
    )
    
    render json: {
      message: 'User activated successfully',
      user: user_summary(@user)
    }
  end

  def deactivate
    authorize! :manage, :user_management
    
    if @user.admin?
      render json: {
        error: 'Cannot deactivate admin users'
      }, status: :forbidden
      return
    end

    @user.update(active: false)
    
    UserAnalytics.track_event(
      current_user,
      'admin_user_deactivated',
      {
        target_user_id: @user.id,
        ip_address: request.remote_ip
      }
    )
    
    render json: {
      message: 'User deactivated successfully',
      user: user_summary(@user)
    }
  end

  def make_admin
    authorize! :manage, :user_management
    
    @user.make_admin!
    
    UserAnalytics.track_event(
      current_user,
      'admin_role_granted',
      {
        target_user_id: @user.id,
        ip_address: request.remote_ip
      }
    )
    
    render json: {
      message: 'User granted admin privileges',
      user: user_summary(@user)
    }
  end

  def remove_admin
    authorize! :manage, :user_management
    
    if User.admins.count <= 1
      render json: {
        error: 'Cannot remove admin privileges from the last admin user'
      }, status: :forbidden
      return
    end

    @user.remove_admin!
    
    UserAnalytics.track_event(
      current_user,
      'admin_role_revoked',
      {
        target_user_id: @user.id,
        ip_address: request.remote_ip
      }
    )
    
    render json: {
      message: 'Admin privileges removed from user',
      user: user_summary(@user)
    }
  end

  private

  def authenticate_admin_user!
    unless current_user&.admin?
      redirect_to admin_login_path, alert: 'Please log in as an administrator'
    end
  end

  def ensure_admin_access
    unless current_user&.admin?
      respond_to do |format|
        format.html { redirect_to admin_login_path, alert: 'Admin access required' }
        format.json { render json: { error: 'Admin access required' }, status: :forbidden }
      end
    end
  end

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :currency)
  end

  def user_summary(user)
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      first_name: user.first_name,
      last_name: user.last_name,
      currency: user.currency,
      admin: user.admin?,
      created_at: user.created_at,
      updated_at: user.updated_at,
      transactions_count: user.transactions.count,
      accounts_count: user.accounts.count,
      budgets_count: user.budgets.count
    }
  end

  def detailed_user_info(user)
    user_summary(user).merge({
      last_sign_in_at: user.created_at, # Use created_at as fallback since trackable is not enabled
      sign_in_count: 0, # Default to 0 since trackable is not enabled
      total_transaction_amount: user.transactions.sum(:amount),
      active_budgets: user.budgets.where('end_date > ?', Date.current).count,
      total_debt: user.debts.sum(:amount),
      saving_goals_count: user.saving_goals.count
    })
  end

  def user_recent_activity(user)
    UserAnalytics.where(user: user)
                 .recent
                 .limit(10)
                 .map do |activity|
      {
        event_type: activity.event_type,
        event_data: activity.event_data,
        created_at: activity.created_at
      }
    end
  end

  def user_financial_summary(user)
    {
      total_income: user.transactions.where('amount > 0').sum(:amount),
      total_expenses: user.transactions.where('amount < 0').sum(:amount),
      net_worth: user.transactions.sum(:amount),
      active_accounts: user.accounts.count,
      monthly_budget: user.budgets.where(
        'start_date <= ? AND end_date >= ?', 
        Date.current, 
        Date.current
      ).sum(:amount)
    }
  end
  
  # Error handling methods
  def handle_user_management_error(exception)
    Rails.logger.error "User Management Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    flash[:alert] = "An error occurred while managing users. Please try again."
    redirect_to admin_users_path
  end
  
  def handle_access_denied(exception)
    flash[:alert] = "You don't have permission to perform this user management action."
    redirect_to admin_root_path
  end
  
  def handle_user_not_found(exception)
    flash[:alert] = "User not found."
    redirect_to admin_users_path
  end
end
