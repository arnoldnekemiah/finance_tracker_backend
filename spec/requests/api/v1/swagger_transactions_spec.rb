# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Transactions API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{auth_token(user)}" }

  path '/api/v1/transactions' do
    get 'List all transactions' do
      tags 'Transactions'
      operationId 'listTransactions'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'List of transactions' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: { '$ref' => '#/components/schemas/transaction' }
          }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    post 'Create a new transaction' do
      let(:account) { user.accounts.first }
      let(:transaction) { { amount: '50.00', transaction_type: 'expense', account_id: account.id, date: Time.current.iso8601 } }
      tags 'Transactions'
      operationId 'createTransaction'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :transaction, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :number, example: 50.00 },
          original_amount: { type: :number, nullable: true },
          original_currency: { type: :string, example: 'USD' },
          category_id: { type: :integer, example: 1 },
          category_name: { type: :string, nullable: true, description: 'Alternative to category_id — creates/finds category by name' },
          transaction_type: { type: :string, enum: %w[income expense transfer], example: 'expense' },
          description: { type: :string, example: 'Weekly groceries' },
          date: { type: :string, format: :'date-time', example: '2026-03-01T10:00:00Z' },
          payment_method: { type: :string, example: 'credit_card' },
          from_account_id: { type: :integer, nullable: true, description: 'Source account (for transfers)' },
          to_account_id: { type: :integer, nullable: true, description: 'Destination account (for transfers)' }
        },
        required: %w[amount transaction_type]
      }

      response '201', 'Transaction created' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/transaction' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        let(:transaction) { { amount: '' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  path '/api/v1/transactions/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Transaction ID'

    let(:id) { create(:transaction, user: user, account: user.accounts.first, category: user.categories.first).id }

    get 'Get transaction details' do
      tags 'Transactions'
      operationId 'getTransaction'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Transaction details' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/transaction' }
        }
        run_test!
      end

      response '404', 'Transaction not found' do
        let(:id) { 0 }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    put 'Update a transaction' do
      let(:transaction) { { description: 'Updated description' } }
      tags 'Transactions'
      operationId 'updateTransaction'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :transaction, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :number },
          original_amount: { type: :number, nullable: true },
          original_currency: { type: :string },
          category_id: { type: :integer },
          category_name: { type: :string, nullable: true },
          transaction_type: { type: :string, enum: %w[income expense transfer] },
          description: { type: :string },
          date: { type: :string, format: :'date-time' },
          payment_method: { type: :string },
          from_account_id: { type: :integer, nullable: true },
          to_account_id: { type: :integer, nullable: true }
        }
      }

      response '200', 'Transaction updated' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/transaction' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        let(:transaction) { { amount: -1 } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    delete 'Delete a transaction' do
      tags 'Transactions'
      operationId 'deleteTransaction'
      security [bearer_auth: []]

      response '204', 'Transaction deleted' do
        run_test!
      end

      response '404', 'Transaction not found' do
        let(:id) { 0 }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Stats ──────────────────────────────────────────────────────────────────
  path '/api/v1/transactions/stats' do
    get 'Get transaction statistics' do
      tags 'Transactions'
      operationId 'getTransactionStats'
      security [bearer_auth: []]
      produces 'application/json'

      parameter name: :start_date, in: :query, type: :string, format: :date, required: false, description: 'Start date (defaults to start of current month)'
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false, description: 'End date (defaults to end of current month)'

      response '200', 'Transaction statistics' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              total_income: { type: :number },
              total_expenses: { type: :number },
              transaction_count: { type: :integer },
              start_date: { type: :string, format: :date },
              end_date: { type: :string, format: :date }
            }
          }
        }
        run_test!
      end
    end
  end

  # ── Spending by Category ───────────────────────────────────────────────────
  path '/api/v1/transactions/spending_by_category' do
    get 'Get spending breakdown by category' do
      tags 'Transactions'
      operationId 'getSpendingByCategory'
      security [bearer_auth: []]
      produces 'application/json'

      parameter name: :start_date, in: :query, type: :string, format: :date, required: false
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false

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
end
