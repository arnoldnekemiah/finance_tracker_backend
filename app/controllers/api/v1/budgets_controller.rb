class Api::V1::BudgetsController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource except: [:create]
  before_action :set_budget, only: %i[show update destroy]
  
  def index
    # Get budgets with Kaminari pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    
    # Get budgets with pagination
    budgets = current_user.budgets
                          .includes(:category)
                          .order(created_at: :desc)
                          .page(page)
                          .per(per_page)
    
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
    Rails.logger.info "=== BUDGET CREATE DEBUG ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Budget params: #{budget_params.inspect}"
    Rails.logger.info "Current user: #{current_user&.id}"
    
    budget = current_user.budgets.build(budget_params)
    Rails.logger.info "Built budget: #{budget.inspect}"
    Rails.logger.info "Budget valid?: #{budget.valid?}"
    Rails.logger.info "Budget errors: #{budget.errors.full_messages}" unless budget.valid?
    
    authorize! :create, budget
    
    if budget.save
      Rails.logger.info "Budget saved successfully: #{budget.id}"
      # Update spent amount and serialize
      budget.update_spent_amount!
      serialized_budget = BudgetSerializer.new(budget).as_json
      render json: { data: serialized_budget }, status: :created
    else
      Rails.logger.error "Budget save failed: #{budget.errors.full_messages}"
      render json: { errors: budget.errors.full_messages }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Budget creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :internal_server_error
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
      :spent,
      :start_date,
      :end_date,
      :period
    )
  end
end
