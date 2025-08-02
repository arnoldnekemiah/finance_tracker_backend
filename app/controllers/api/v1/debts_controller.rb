class Api::V1::DebtsController < ApplicationController
  load_and_authorize_resource
  
  def index
    debts = current_user.debts.includes(:user)
    render json: debts, each_serializer: DebtSerializer
  end

  def show
    debt = current_user.debts.find(params[:id])
    render json: debt, serializer: DebtSerializer
  end

  def create
    debt = current_user.debts.build(debt_params)
    if debt.save
      render json: debt, serializer: DebtSerializer, status: :created
    else
      render json: { errors: debt.errors }, status: :unprocessable_entity
    end
  end

  def update
    debt = current_user.debts.find(params[:id])
    if debt.update(debt_params)
      render json: debt, serializer: DebtSerializer
    else
      render json: { errors: debt.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    debt = current_user.debts.find(params[:id])
    debt.destroy
    head :no_content
  end

  def mark_as_paid
    debt = current_user.debts.find(params[:id])
    if debt.update(status: 'paid')
      render json: debt, serializer: DebtSerializer
    else
      render json: { errors: debt.errors }, status: :unprocessable_entity
    end
  end

  private

  def debt_params
    params.require(:debt).permit(
      :title,
      :amount,
      :creditor,
      :description,
      :due_date,
      :status,
      :debt_type,
      :interest_rate,
      :is_recurring,
      :recurring_period
    )
  end
end
