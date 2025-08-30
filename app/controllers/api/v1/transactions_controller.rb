class Api::V1::TransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource except: :create
  before_action :set_transaction, only: %i[show update destroy]
  
  def index
    transactions = current_user.transactions.includes(:category, :account)

    # Filtering
    transactions = transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?
    transactions = transactions.where(category_id: params[:category_id]) if params[:category_id].present?
    if params[:start_date].present? && params[:end_date].present?
      transactions = transactions.where(date: params[:start_date]..params[:end_date])
    end

    # Sorting
    if params[:sort_by].present?
      direction = params[:sort_direction] == 'desc' ? :desc : :asc
      transactions = transactions.order(params[:sort_by] => direction)
    else
      transactions = transactions.order(date: :desc)
    end
    
    render json: transactions, each_serializer: TransactionSerializer
  end
  
  def show
    render json: @transaction, serializer: TransactionSerializer
  end
  
  def create
    transaction_type = params.dig(:transaction, :transaction_type) || params[:transaction_type]
    
    unless %w[income expense].include?(transaction_type)
      return render json: { 
        errors: { 
          transaction_type: ["must be either 'income' or 'expense'"] 
        } 
      }, status: :unprocessable_entity
    end
    
    result = Transactions::CreatorService.new(current_user, params).call
    
    if result[:success]
      @transaction = result[:transaction]
      authorize! :create, @transaction
      render json: @transaction, serializer: TransactionSerializer, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
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
    if @transaction.destroy
      head :no_content
    else
      render json: { errors: @transaction.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end
      
  def transaction_params
    params.require(:transaction).permit(
      :amount,
      :description,
      :transaction_type,
      :date,
      :notes,
      :payment_method,
      :category_id,
      :account_id
    )
  end
end
