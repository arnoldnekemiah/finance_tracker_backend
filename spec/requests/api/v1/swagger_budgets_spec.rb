# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Budgets API', type: :request do
  path '/api/v1/budgets' do
    get 'List all budgets (paginated)' do
      tags 'Budgets'
      operationId 'listBudgets'
      security [bearer_auth: []]
      produces 'application/json'

      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number (default: 1)'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page (default: 20)'

      response '200', 'Paginated list of budgets' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: { '$ref' => '#/components/schemas/budget' }
          },
          pagination: { '$ref' => '#/components/schemas/pagination' }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    post 'Create a new budget' do
      tags 'Budgets'
      operationId 'createBudget'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :budget, in: :body, schema: {
        type: :object,
        properties: {
          category_id: { type: :integer, example: 1 },
          limit: { type: :number, example: 500.00, description: 'Budget limit amount' },
          spent: { type: :number, example: 0.00 },
          start_date: { type: :string, format: :'date-time', example: '2026-03-01T00:00:00Z' },
          end_date: { type: :string, format: :'date-time', example: '2026-03-31T23:59:59Z' },
          period: { type: :string, example: 'monthly', description: 'e.g. weekly, monthly, yearly' }
        },
        required: %w[category_id limit start_date end_date]
      }

      response '201', 'Budget created' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/budget' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  path '/api/v1/budgets/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Budget ID'

    get 'Get budget details' do
      tags 'Budgets'
      operationId 'getBudget'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Budget details' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/budget' }
        }
        run_test!
      end

      response '404', 'Budget not found' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    put 'Update a budget' do
      tags 'Budgets'
      operationId 'updateBudget'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :budget, in: :body, schema: {
        type: :object,
        properties: {
          category_id: { type: :integer },
          limit: { type: :number },
          spent: { type: :number },
          start_date: { type: :string, format: :'date-time' },
          end_date: { type: :string, format: :'date-time' },
          period: { type: :string }
        }
      }

      response '200', 'Budget updated' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/budget' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    delete 'Delete a budget' do
      tags 'Budgets'
      operationId 'deleteBudget'
      security [bearer_auth: []]

      response '204', 'Budget deleted' do
        run_test!
      end

      response '404', 'Budget not found' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Active Budgets ─────────────────────────────────────────────────────────
  path '/api/v1/budgets/active' do
    get 'List currently active budgets' do
      tags 'Budgets'
      operationId 'getActiveBudgets'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Active budgets' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: { '$ref' => '#/components/schemas/budget' }
          }
        }
        run_test!
      end
    end
  end

  # ── Budget Summary ─────────────────────────────────────────────────────────
  path '/api/v1/budgets/summary' do
    get 'Get overall budget summary' do
      tags 'Budgets'
      operationId 'getBudgetSummary'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Budget summary' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              total_budget: { type: :number },
              total_spent: { type: :number },
              total_remaining: { type: :number },
              budget_count: { type: :integer },
              over_budget_count: { type: :integer },
              budgets: {
                type: :array,
                items: { '$ref' => '#/components/schemas/budget' }
              }
            }
          }
        }
        run_test!
      end
    end
  end
end
