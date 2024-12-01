require 'swagger_helper'

RSpec.describe 'Recurring Transactions API', type: :request do
  path '/api/v1/recurring_transactions' do
    get 'Lists all active recurring transactions' do
      tags 'Recurring Transactions'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'recurring transactions found' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  amount: { type: :number },
                  category: { type: :string },
                  description: { type: :string },
                  period: { type: :string },
                  start_date: { type: :string, format: 'date-time' },
                  end_date: { type: :string, format: 'date-time' },
                  is_active: { type: :boolean }
                }
              }
            }
          }
        run_test!
      end
    end

    post 'Creates a recurring transaction' do
      tags 'Recurring Transactions'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :recurring_transaction, in: :body, schema: {
        type: :object,
        properties: {
          recurring_transaction: {
            type: :object,
            properties: {
              amount: { type: :number },
              category: { type: :string },
              description: { type: :string },
              period: { type: :string, enum: ['daily', 'weekly', 'monthly', 'yearly'] },
              start_date: { type: :string, format: 'date-time' },
              end_date: { type: :string, format: 'date-time' },
              is_active: { type: :boolean }
            },
            required: ['amount', 'category', 'period', 'start_date']
          }
        }
      }

      response '201', 'recurring transaction created' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            amount: { type: :number },
            category: { type: :string },
            description: { type: :string },
            period: { type: :string },
            start_date: { type: :string, format: 'date-time' },
            end_date: { type: :string, format: 'date-time' },
            is_active: { type: :boolean }
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

  path '/api/v1/recurring_transactions/{id}' do
    parameter name: :id, in: :path, type: :integer

    put 'Updates a recurring transaction' do
      tags 'Recurring Transactions'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :recurring_transaction, in: :body, schema: {
        type: :object,
        properties: {
          recurring_transaction: {
            type: :object,
            properties: {
              amount: { type: :number },
              category: { type: :string },
              description: { type: :string },
              period: { type: :string, enum: ['daily', 'weekly', 'monthly', 'yearly'] },
              start_date: { type: :string, format: 'date-time' },
              end_date: { type: :string, format: 'date-time' },
              is_active: { type: :boolean }
            }
          }
        }
      }

      response '200', 'recurring transaction updated' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            amount: { type: :number },
            category: { type: :string },
            description: { type: :string },
            period: { type: :string },
            start_date: { type: :string, format: 'date-time' },
            end_date: { type: :string, format: 'date-time' },
            is_active: { type: :boolean }
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