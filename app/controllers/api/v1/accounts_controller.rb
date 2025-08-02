class Api::V1::AccountsController < ApplicationController
  load_and_authorize_resource
  
  def index
    accounts = current_user.accounts.active.includes(:user)
    render json: accounts, each_serializer: AccountSerializer
  end

  def show
    account = current_user.accounts.find(params[:id])
    render json: account, serializer: AccountSerializer
  end

  def create
    account = current_user.accounts.build(account_params)
    if account.save
      render json: account, serializer: AccountSerializer, status: :created
    else
      render json: { errors: account.errors }, status: :unprocessable_entity
    end
  end

  def update
    account = current_user.accounts.find(params[:id])
    if account.update(account_params)
      render json: account, serializer: AccountSerializer
    else
      render json: { errors: account.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    account = current_user.accounts.find(params[:id])
    account.update(is_active: false)
    head :no_content
  end

  def update_balance
    account = current_user.accounts.find(params[:id])
    if account.update(balance: params[:balance])
      render json: account, serializer: AccountSerializer
    else
      render json: { errors: account.errors }, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(
      :name,
      :account_type,
      :account_number,
      :bank_name,
      :balance,
      :currency,
      :description,
      :is_active
    )
  end
end
