class Api::V1::AccountsController < ApplicationController
  include Authenticatable
  before_action :set_account, only: %i[show update destroy]

  def index
    accounts = current_user.accounts.active
    render json: { status: 'success', data: accounts.map { |a| AccountSerializer.new(a).as_json } }
  end

  def show
    render json: { status: 'success', data: AccountSerializer.new(@account).as_json }
  end

  def create
    account = current_user.accounts.build(account_params)
    if account.save
      render json: { status: 'success', data: AccountSerializer.new(account).as_json }, status: :created
    else
      render json: { status: 'error', error: account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @account.update(account_params)
      render json: { status: 'success', data: AccountSerializer.new(@account).as_json }
    else
      render json: { status: 'error', error: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @account.update(is_active: false)
    head :no_content
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:id])
  end

  def account_params
    params.permit(:name, :account_type, :bank_name, :balance, :currency, :account_number, :is_active)
  end
end
