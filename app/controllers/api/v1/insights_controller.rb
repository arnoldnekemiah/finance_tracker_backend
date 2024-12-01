class Api::V1::InsightsController < ApplicationController
    load_and_authorize_resource
    
    def overview
        monthly_data = {
          total_income: current_user.transactions.income.this_month.sum(:amount),
          total_expenses: current_user.transactions.expense.this_month.sum(:amount),
          top_categories: top_spending_categories,
          monthly_trend: calculate_monthly_trend
        }
        
        render json: monthly_data
      end

      def spending_by_category
        categories = current_user.transactions
                               .expense
                               .group(:category)
                               .sum(:amount)
        
        render json: categories
      end

      def weekly_trends
        weekly_data = current_user.transactions
                                .expense
                                .where('date >= ?', 1.week.ago)
                                .group_by_day(:date)
                                .sum(:amount)
        
        render json: weekly_data
      end

      private

      def top_spending_categories
        current_user.transactions
                   .expense
                   .group(:category)
                   .sum(:amount)
                   .sort_by { |_, amount| -amount }
                   .first(5)
      end

      def calculate_monthly_trend
        current_month = current_user.transactions.expense.this_month.sum(:amount)
        last_month = current_user.transactions.expense.last_month.sum(:amount)
        
        return 0 if last_month.zero?
        ((current_month - last_month) / last_month.to_f) * 100
      end
end
