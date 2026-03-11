class Api::V1::BudgetsController < Api::BaseController
  include Authenticatable
  before_action :set_budget, only: %i[show update destroy]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 20

    budgets = current_user.budgets.includes(:category).order(created_at: :desc).page(page).per(per_page)
    budgets.each(&:update_spent_amount!)

    render json: {
      status: 'success',
      data: budgets.map { |b| BudgetSerializer.new(b).as_json },
      pagination: {
        current_page: budgets.current_page,
        total_pages: budgets.total_pages,
        total_count: budgets.total_count,
        per_page: per_page.to_i
      }
    }
  end

  def show
    @budget.update_spent_amount!
    render json: { status: 'success', data: BudgetSerializer.new(@budget).as_json }
  end

  def create
    budget = current_user.budgets.build(budget_params)
    if budget.save
      budget.update_spent_amount!
      render json: { status: 'success', data: BudgetSerializer.new(budget).as_json }, status: :created
    else
      render json: { status: 'error', error: budget.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @budget.update(budget_params)
      @budget.update_spent_amount!
      render json: { status: 'success', data: BudgetSerializer.new(@budget).as_json }
    else
      render json: { status: 'error', error: @budget.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @budget.destroy
    head :no_content
  end

  # GET /api/v1/budgets/active
  def active
    budgets = current_user.budgets.active.includes(:category)
    budgets.each(&:update_spent_amount!)
    render json: { status: 'success', data: budgets.map { |b| BudgetSerializer.new(b).as_json } }
  end

  # GET /api/v1/budgets/summary
  def summary
    active_budgets = current_user.budgets.active.includes(:category)
    active_budgets.each(&:update_spent_amount!)

    total_budget = active_budgets.sum(:limit)
    total_spent = active_budgets.sum(:spent)

    render json: {
      status: 'success',
      data: {
        total_budget: total_budget.to_f,
        total_spent: total_spent.to_f,
        total_remaining: (total_budget - total_spent).to_f,
        budget_count: active_budgets.count,
        over_budget_count: active_budgets.count(&:over_budget?),
        budgets: active_budgets.map { |b| BudgetSerializer.new(b).as_json }
      }
    }
  end

  private

  def set_budget
    @budget = current_user.budgets.find(params[:id])
  end

  def budget_params
    params.permit(:category_id, :limit, :spent, :start_date, :end_date, :period)
  end
end
