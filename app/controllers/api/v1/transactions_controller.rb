class Api::V1::TransactionsController < ApplicationController
  load_and_authorize_resource
  before_action :set_transaction, only: %i[show update destroy]
  
  def index
    transactions = current_user.transactions.includes(:category, :account)
    render json: transactions, each_serializer: TransactionSerializer
  end

  def show
    render json: @transaction, serializer: TransactionSerializer
  end

  def create
    transaction = current_user.transactions.build(transaction_params)
    if transaction.save
      render json: transaction, serializer: TransactionSerializer, status: :created
    else
      render json: { errors: transaction.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      render json: @transaction, serializer: TransactionSerializer
    else
      render json: { errors: @transaction.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    head :no_content
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end
      
  def transaction_params
    params.require(:transaction).permit(
      :amount, 
      :category_id,
      :account_id,
      :transaction_type,
      :description,
      :date, 
      :notes, 
      :payment_method
    )
  end
end
