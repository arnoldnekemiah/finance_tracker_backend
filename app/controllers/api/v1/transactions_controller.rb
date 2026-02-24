class Api::V1::TransactionsController < ApplicationController
  include Authenticatable
  before_action :set_transaction, only: %i[show update destroy]

  def index
    transactions = current_user.transactions.includes(:category).order(date: :desc, created_at: :desc)
    render json: { status: 'success', data: transactions.map { |t| TransactionSerializer.new(t).as_json } }
  end

  def show
    render json: { status: 'success', data: TransactionSerializer.new(@transaction).as_json }
  end

  def create
    transaction = current_user.transactions.build(transaction_params)
    if transaction.save
      render json: { status: 'success', data: TransactionSerializer.new(transaction).as_json }, status: :created
    else
      render json: { status: 'error', error: transaction.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      render json: { status: 'success', data: TransactionSerializer.new(@transaction).as_json }
    else
      render json: { status: 'error', error: @transaction.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    head :no_content
  end

  # GET /api/v1/transactions/stats
  def stats
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current.end_of_month

    transactions = current_user.transactions.where(date: start_date..end_date)

    render json: {
      status: 'success',
      data: {
        total_income: transactions.income.sum(:amount),
        total_expenses: transactions.expense.sum(:amount),
        transaction_count: transactions.count,
        start_date: start_date,
        end_date: end_date
      }
    }
  end

  # GET /api/v1/transactions/spending_by_category
  def spending_by_category
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current.end_of_month

    categories = current_user.transactions
                            .expense
                            .where(date: start_date..end_date)
                            .joins(:category)
                            .group('categories.id, categories.name, categories.icon, categories.color')
                            .sum(:amount)

    total = categories.values.sum

    data = categories.map do |(cat_id, name, icon, color), amount|
      {
        category_id: cat_id,
        category_name: name,
        icon: icon,
        color: color,
        amount: amount,
        percentage: total > 0 ? ((amount / total) * 100).round(1) : 0
      }
    end.sort_by { |c| -c[:amount] }

    render json: { status: 'success', data: data }
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.permit(
      :amount, :original_amount, :original_currency, :category_id, :category_name,
      :transaction_type, :description, :date, :payment_method,
      :from_account_id, :to_account_id
    )
  end
end
