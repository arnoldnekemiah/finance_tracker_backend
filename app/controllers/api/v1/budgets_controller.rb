class Api::V1::BudgetsController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource except: [:create]
  before_action :set_budget, only: %i[show update destroy]
  
  def index
    budgets = current_user.budgets.includes(:category)
    serialized_budgets = budgets.map { |budget| BudgetSerializer.new(budget).as_json }
    render json: { data: serialized_budgets }
  end

  def show
    render json: @budget, serializer: BudgetSerializer
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Budget not found" }, status: :not_found
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
      render json: budget, serializer: BudgetSerializer, status: :created
    else
      Rails.logger.error "Budget save failed: #{budget.errors.full_messages}"
      render json: { errors: budget.errors }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Budget creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :internal_server_error
  end

  def update
    if @budget.update(budget_params)
      render json: @budget, serializer: BudgetSerializer
    else
      render json: { errors: @budget.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Budget not found" }, status: :not_found
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
