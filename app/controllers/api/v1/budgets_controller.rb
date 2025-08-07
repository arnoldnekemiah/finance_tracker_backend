class Api::V1::BudgetsController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource
  before_action :set_budget, only: %i[show update destroy]
  
  def index
    budgets = current_user.budgets.includes(:category)
    render json: budgets, each_serializer: BudgetSerializer
  end

  def show
    render json: @budget, serializer: BudgetSerializer
  end

  def create
    budget = current_user.budgets.build(budget_params)
    if budget.save
      render json: budget, serializer: BudgetSerializer, status: :created
    else
      render json: { errors: budget.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @budget.update(budget_params)
      render json: @budget, serializer: BudgetSerializer
    else
      render json: { errors: @budget.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @budget.destroy
    head :no_content
  end

  private

  def set_budget
    @budget = current_user.budgets.find(params[:id])
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
