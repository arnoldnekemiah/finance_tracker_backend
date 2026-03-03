# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Insights API', type: :request do
  # ── Monthly Overview ───────────────────────────────────────────────────────
  path '/api/v1/insights/monthly_overview' do
    get 'Get monthly income/expense overview' do
      tags 'Insights'
      operationId 'getMonthlyOverview'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Monthly overview' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              total_income: { type: :number },
              total_expenses: { type: :number },
              top_categories: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    category: { type: :string },
                    amount: { type: :number }
                  }
                }
              }
            }
          }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Spending by Category ───────────────────────────────────────────────────
  path '/api/v1/insights/spending_by_category' do
    get 'Get spending breakdown by category (last 30 days)' do
      tags 'Insights'
      operationId 'getInsightsSpendingByCategory'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Spending by category' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: {
              type: :object,
              properties: {
                category_id: { type: :integer },
                category_name: { type: :string },
                icon: { type: :string },
                color: { type: :string },
                amount: { type: :number },
                percentage: { type: :number }
              }
            }
          }
        }
        run_test!
      end
    end
  end

  # ── Weekly Trends ──────────────────────────────────────────────────────────
  path '/api/v1/insights/weekly_trends' do
    get 'Get weekly spending trends (last 4 weeks)' do
      tags 'Insights'
      operationId 'getWeeklyTrends'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Weekly spending trends' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: {
              type: :object,
              properties: {
                week: { type: :integer },
                start_date: { type: :string, format: :date },
                end_date: { type: :string, format: :date },
                spending: { type: :number }
              }
            }
          }
        }
        run_test!
      end
    end
  end

  # ── Spending Comparison ────────────────────────────────────────────────────
  path '/api/v1/insights/spending_comparison' do
    get 'Compare spending between current and last month' do
      tags 'Insights'
      operationId 'getSpendingComparison'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Spending comparison' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              current_month: { type: :number },
              last_month: { type: :number },
              percentage_change: { type: :number }
            }
          }
        }
        run_test!
      end
    end
  end
end
