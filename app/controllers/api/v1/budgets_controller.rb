class Api::V1::BudgetsController < ApplicationController
    def index
        budgets = current_user.budgets
        render json: budgets, each_serializer: BudgetSerializer
    end

    def create
        budget = current_user.budgets.build(budget_params)
        if budget.save
          render json: budget, status: :created
        else
          render json: { errors: budget.errors }, status: :unprocessable_entity
        end
      end

      private

      def budget_params
        params.require(:budget).permit(
          :category,
          :limit,
          :spent,
          :start_date,
          :end_date
        )
      end
end
