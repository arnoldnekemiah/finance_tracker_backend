# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Dashboard API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{auth_token(user)}" }

  # ── Dashboard Overview ─────────────────────────────────────────────────────
  path '/api/v1/dashboard/overview' do
    get 'Get full dashboard overview' do
      tags 'Dashboard'
      operationId 'getDashboardOverview'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Dashboard overview data' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: {
              type: :object,
              properties: {
                balance_overview: {
                  type: :object,
                  properties: {
                    current_balance: { type: :number },
                    monthly_income: { type: :number },
                    monthly_expenses: { type: :number },
                    net_income: { type: :number }
                  }
                },
                monthly_summary: {
                  type: :object,
                  properties: {
                    budget_utilization: { type: :number },
                    income: { type: :number },
                    expenses: { type: :number },
                    savings_rate: { type: :number }
                  }
                },
                weekly_spending: {
                  type: :object,
                  properties: {
                    current_week: { type: :array, items: { type: :number }, description: '7 daily amounts' },
                    labels: { type: :array, items: { type: :string }, example: %w[Mon Tue Wed Thu Fri Sat Sun] }
                  }
                },
                top_spending_categories: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      category_id: { type: :integer },
                      category_name: { type: :string },
                      amount: { type: :number },
                      percentage: { type: :number },
                      icon: { type: :string },
                      color: { type: :string }
                    }
                  }
                },
                recent_transactions: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :integer },
                      amount: { type: :number },
                      description: { type: :string },
                      category: { type: :string },
                      date: { type: :string },
                      type: { type: :string }
                    }
                  }
                },
                quick_stats: {
                  type: :object,
                  properties: {
                    total_budgets: { type: :integer },
                    active_debts: { type: :integer },
                    saving_goals: { type: :integer },
                    transactions_this_month: { type: :integer }
                  }
                }
              }
            }
          }
        )
        run_test!
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end
  end

  # ── Financial Overview ─────────────────────────────────────────────────────
  path '/api/v1/dashboard/financial_overview' do
    get 'Get financial overview summary' do
      tags 'Dashboard'
      operationId 'getFinancialOverview'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Financial overview' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: {
              type: :object,
              properties: {
                total_balance: { type: :number },
                total_income: { type: :number },
                total_expenses: { type: :number },
                net_worth: { type: :number },
                savings_rate: { type: :number }
              }
            }
          }
        )
        run_test!
      end
      response '401', 'Unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end    end
  end

  # ── Dashboard Spending by Category ─────────────────────────────────────────
  path '/api/v1/dashboard/spending_by_category' do
    get 'Get dashboard spending by category' do
      tags 'Dashboard'
      operationId 'getDashboardSpendingByCategory'
      security [bearer_auth: []]
      produces 'application/json'

      parameter name: :start_date, in: :query, type: :string, format: :date, required: false
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false

      response '200', 'Spending by category' do
        schema(
          type: :object,
          properties: {
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
        )
        run_test!
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end
  end
end
