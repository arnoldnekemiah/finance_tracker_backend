class Api::V1::BudgetsController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource except: [:create]
  before_action :set_budget, only: %i[show update destroy]
  
  def index
    budgets = current_user.budgets.includes(:category)

    # Filtering
    budgets = budgets.where(period: params[:period]) if params[:period].present?
    budgets = budgets.where(category_id: params[:category_id]) if params[:category_id].present?

    # Sorting
    if params[:sort_by].present?
      direction = params[:sort_direction] == 'desc' ? :desc : :asc
      sort_column = "limit_cents" if params[:sort_by] == "limit"
      sort_column = "spent_cents" if params[:sort_by] == "spent"
      sort_column ||= params[:sort_by]
      budgets = budgets.order(sort_column => direction)
    else
      budgets = budgets.order(end_date: :desc)
    end

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    budgets = budgets.page(page).per(per_page)
    
    # Update spent amounts for all budgets before serializing
    budgets.each(&:update_spent_amount!)
    
    # Serialize budgets with all calculated fields
    serialized_budgets = budgets.map do |budget|
      BudgetSerializer.new(budget).as_json
    end
    
    # Build pagination metadata
    pagination = {
      current_page: budgets.current_page,
      total_pages: budgets.total_pages,
      total_count: budgets.total_count,
      per_page: per_page.to_i
    }
    
    render json: {
      data: serialized_budgets,
      pagination: pagination
    }
  rescue => e
    Rails.logger.error "Budget index error: #{e.message}"
    render json: { error: 'Failed to fetch budgets' }, status: :internal_server_error
  end

  def show
    # Update spent amount before showing
    @budget.update_spent_amount!
    
    serialized_budget = BudgetSerializer.new(@budget).as_json
    render json: { data: serialized_budget }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Budget not found" }, status: :not_found
  rescue => e
    Rails.logger.error "Budget show error: #{e.message}"
    render json: { error: 'Failed to fetch budget' }, status: :internal_server_error
  end

  def create
    authorize! :create, Budget
    result = Budgets::CreatorService.new(current_user, budget_params).call
    if result[:success]
      budget = result[:budget]
      budget.update_spent_amount!
      serialized_budget = BudgetSerializer.new(budget).as_json
      render json: { data: serialized_budget }, status: :created
    else
      render json: { errors: result[:errors].full_messages }, status: :unprocessable_entity
    end
  rescue CanCan::AccessDenied => e
    render json: { error: e.message }, status: :forbidden
  rescue => e
    Rails.logger.error "Budget creation error: #{e.message}"
    render json: { error: 'Failed to create budget' }, status: :internal_server_error
  end

  def update
    if @budget.update(budget_params)
      # Update spent amount and serialize
      @budget.update_spent_amount!
      serialized_budget = BudgetSerializer.new(@budget).as_json
      render json: { data: serialized_budget }
    else
      render json: { errors: @budget.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Budget not found" }, status: :not_found
  rescue => e
    Rails.logger.error "Budget update error: #{e.message}"
    render json: { error: 'Failed to update budget' }, status: :internal_server_error
  end

  def destroy
    @budget.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Budget not found" }, status: :not_found
  end

  def bulk_create
    authorize! :create, Budget
    budgets_params = params.require(:budgets).map do |p|
      p.permit(
        :category_id,
        :limit,
        :original_currency,
        :start_date,
        :end_date,
        :period
      )
    end

    created_budgets = []
    errors = []

    budgets_params.each do |budget_params|
      result = Budgets::CreatorService.new(current_user, budget_params).call
      if result[:success]
        created_budgets << result[:budget]
      else
        errors << { params: budget_params, errors: result[:errors].full_messages }
      end
    end

    if errors.empty?
      serialized_budgets = created_budgets.map { |b| BudgetSerializer.new(b).as_json }
      render json: { data: serialized_budgets }, status: :created
    else
      render json: { errors: errors }, status: :unprocessable_entity
    end
  rescue CanCan::AccessDenied => e
    render json: { error: e.message }, status: :forbidden
  rescue => e
    Rails.logger.error "Budget bulk creation error: #{e.message}"
    render json: { error: 'Failed to create budgets' }, status: :internal_server_error
  end

  private

  def set_budget
    @budget = current_user.budgets.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Budget not found" }, status: :not_found
  end

  def budget_params
    params.require(:budget).permit(
      :category_id,
      :limit,
      :original_currency,
      :start_date,
      :end_date,
      :period
    )
  end
end
