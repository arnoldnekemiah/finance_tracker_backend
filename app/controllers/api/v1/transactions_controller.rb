class Api::V1::TransactionsController < ApplicationController
    def index
        transactions = current_user.transactions
        render json: transactions
    end
    def create
        transaction = current_user.transactions.build(transaction_params)
        if transaction.save
          render json: transaction, status: :created
        else
          render json: { errors: transaction.errors }, status: :unprocessable_entity
        end
    end

    private
      
    def transaction_params
        params.require(:transaction).permit(
          :amount, 
          :category, 
          :type, 
          :date, 
          :notes, 
          :recurring_id
        )
    end
end
