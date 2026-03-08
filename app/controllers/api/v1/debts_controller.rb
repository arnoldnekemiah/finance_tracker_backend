class Api::V1::DebtsController < Api::BaseController
  include Authenticatable
  before_action :set_debt, only: %i[show update destroy]

  def index
    debts = current_user.debts.order(created_at: :desc)
    render json: { status: 'success', data: debts.map { |d| DebtSerializer.new(d).as_json } }
  end

  def show
    render json: { status: 'success', data: DebtSerializer.new(@debt).as_json }
  end

  def create
    debt = current_user.debts.build(debt_params)
    if debt.save
      render json: { status: 'success', data: DebtSerializer.new(debt).as_json }, status: :created
    else
      render json: { status: 'error', error: debt.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @debt.update(debt_params)
      render json: { status: 'success', data: DebtSerializer.new(@debt).as_json }
    else
      render json: { status: 'error', error: @debt.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @debt.destroy
    head :no_content
  end

  private

  def set_debt
    @debt = current_user.debts.find(params[:id])
  end

  def debt_params
    params.permit(:title, :amount, :creditor, :due_date, :status, :debt_type, :interest_rate, :is_recurring)
  end
end
