class Api::V1::InsightsController < ApplicationController
    load_and_authorize_resource class: false
    
    rescue_from StandardError do |e|
      render json: { error: 'An error occurred while processing insights' }, status: :internal_server_error
    end
    
    def overview
        begin
          monthly_data = {
            total_income: current_user.transactions.income.this_month.sum(:amount),
            total_expenses: current_user.transactions.expense.this_month.sum(:amount),
            top_categories: top_spending_categories,
            monthly_trend: calculate_monthly_trend
          }
          
          render json: { data: monthly_data }, status: :ok
        rescue => e
          render json: { error: 'Failed to fetch overview data' }, status: :unprocessable_entity
        end
      end

      def spending_by_category
        begin
          categories = current_user.transactions
                                 .expense
                                 .where('date >= ?', 30.days.ago)
                                 .group(:category)
                                 .sum(:amount)
          
          render json: { data: categories }, status: :ok
        rescue => e
          render json: { error: 'Failed to fetch category data' }, status: :unprocessable_entity
        end
      end

      def weekly_trends
        begin
          weekly_data = current_user.transactions
                                  .expense
                                  .where('date >= ?', 1.week.ago)
                                  .group_by_day(:date)
                                  .sum(:amount)
          
          render json: { data: weekly_data }, status: :ok
        rescue => e
          render json: { error: 'Failed to fetch weekly trends' }, status: :unprocessable_entity
        end
      end

      private

      def top_spending_categories
        current_user.transactions
                   .expense
                   .where('date >= ?', 30.days.ago)
                   .group(:category)
                   .sum(:amount)
                   .sort_by { |_, amount| -amount }
                   .first(5)
                   .to_h
      end

      def calculate_monthly_trend
        current_month = current_user.transactions.expense.this_month.sum(:amount)
        last_month = current_user.transactions.expense.last_month.sum(:amount)
        
        return 0 if last_month.zero?
        ((current_month - last_month) / last_month.to_f * 100).round(2)
      end
end
