class Api::V1::TransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  load_and_authorize_resource
  before_action :set_transaction, only: %i[show update destroy]
  
  def index
    transactions = current_user.transactions.includes(:category, :from_account, :to_account)

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

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    transactions = transactions.page(page).per(per_page)

    render json: transactions, each_serializer: TransactionSerializer, meta: {
      pagination: {
        current_page: transactions.current_page,
        total_pages: transactions.total_pages,
        total_count: transactions.total_count,
        per_page: per_page.to_i
      }
    }
  end

  def show
    render json: @transaction, serializer: TransactionSerializer
  end

  def create
    result = Transactions::CreatorService.new(current_user, transaction_params).call
    if result[:success]
      render json: result[:transaction], serializer: TransactionSerializer, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def update
    result = Transactions::UpdaterService.new(@transaction, transaction_params).call
    if result[:success]
      render json: result[:transaction], serializer: TransactionSerializer
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def destroy
    result = Transactions::DestroyerService.new(@transaction).call
    if result[:success]
      head :no_content
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def bulk_create
    transactions_params = params.require(:transactions).map do |p|
      p.permit(
        :original_amount,
        :original_currency,
        :category_id,
        :account_id,
        :from_account_id,
        :to_account_id,
        :transaction_type,
        :description,
        :date,
        :notes,
        :payment_method
      )
    end

    created_transactions = []
    errors = []

    transactions_params.each do |transaction_params|
      result = Transactions::CreatorService.new(current_user, transaction_params).call
      if result[:success]
        created_transactions << result[:transaction]
      else
        errors << { params: transaction_params, errors: result[:errors] }
      end
    end

    if errors.empty?
      render json: created_transactions, each_serializer: TransactionSerializer, status: :created
    else
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end
      
  def transaction_params
    params.require(:transaction).permit(
      :original_amount,
      :original_currency,
      :category_id,
      :account_id,
      :from_account_id,
      :to_account_id,
      :transaction_type,
      :description,
      :date, 
      :notes, 
      :payment_method
    )
  end
end
