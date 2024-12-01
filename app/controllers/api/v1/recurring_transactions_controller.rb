class Api::V1::RecurringTransactionsController < ApplicationController
    def index
        recurring_transactions = current_user.recurring_transactions.active
        render json: recurring_transactions
      end

      def create
        recurring_transaction = current_user.recurring_transactions.build(recurring_transaction_params)
        if recurring_transaction.save
          render json: recurring_transaction, status: :created
        else
          render json: { errors: recurring_transaction.errors }, status: :unprocessable_entity
        end
      end

      def update
        recurring_transaction = current_user.recurring_transactions.find(params[:id])
        if recurring_transaction.update(recurring_transaction_params)
          render json: recurring_transaction
        else
          render json: { errors: recurring_transaction.errors }, status: :unprocessable_entity
        end
      end

      private

      def recurring_transaction_params
        params.require(:recurring_transaction).permit(
          :amount,
          :category,
          :description,
          :period,
          :start_date,
          :end_date,
          :is_active
        )
      end
end
