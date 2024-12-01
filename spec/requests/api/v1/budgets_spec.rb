require 'swagger_helper'

RSpec.describe 'Budgets API', type: :request do
  path '/api/v1/budgets' do
    get 'Lists all budgets' do
      tags 'Budgets'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'budgets found' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  category: { type: :string },
                  limit: { type: :number },
                  spent: { type: :number },
                  start_date: { type: :string, format: 'date-time' },
                  end_date: { type: :string, format: 'date-time' },
                  remaining_amount: { type: :number },
                  percentage_used: { type: :number },
                  is_over_budget: { type: :boolean }
                }
              }
            }
          }
        run_test!
      end
    end

    post 'Creates a budget' do
      tags 'Budgets'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :budget, in: :body, schema: {
        type: :object,
        properties: {
          budget: {
            type: :object,
            properties: {
              category: { type: :string },
              limit: { type: :number },
              spent: { type: :number },
              start_date: { type: :string, format: 'date-time' },
              end_date: { type: :string, format: 'date-time' }
            },
            required: ['category', 'limit', 'start_date', 'end_date']
          }
        }
      }

      response '201', 'budget created' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            category: { type: :string },
            limit: { type: :number },
            spent: { type: :number },
            start_date: { type: :string, format: 'date-time' },
            end_date: { type: :string, format: 'date-time' }
          }
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            errors: { type: :object }
          }
        run_test!
      end
    end
  end
end 