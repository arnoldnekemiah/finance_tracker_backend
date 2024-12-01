require 'swagger_helper'

RSpec.describe 'Transactions API', type: :request do
  path '/api/v1/transactions' do
    get 'Lists all transactions' do
      tags 'Transactions'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'transactions found' do
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
                  type: { type: :string },
                  date: { type: :string, format: 'date-time' },
                  notes: { type: :string },
                  recurring_id: { type: :string, nullable: true }
                }
              }
            }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        run_test!
      end
    end

    post 'Creates a transaction' do
      tags 'Transactions'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :transaction, in: :body, schema: {
        type: :object,
        properties: {
          transaction: {
            type: :object,
            properties: {
              amount: { type: :number },
              category: { type: :string },
              type: { type: :string, enum: ['income', 'expense'] },
              date: { type: :string, format: 'date-time' },
              notes: { type: :string },
              recurring_id: { type: :string, nullable: true }
            },
            required: ['amount', 'category', 'type', 'date']
          }
        }
      }

      response '201', 'transaction created' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            amount: { type: :number },
            category: { type: :string },
            type: { type: :string },
            date: { type: :string, format: 'date-time' },
            notes: { type: :string },
            recurring_id: { type: :string, nullable: true }
          }
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            errors: {
              type: :object
            }
          }
        run_test!
      end
    end
  end
end 