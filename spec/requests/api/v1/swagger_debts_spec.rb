# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Debts API', type: :request do
  path '/api/v1/debts' do
    get 'List all debts' do
      tags 'Debts'
      operationId 'listDebts'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'List of debts' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: { '$ref' => '#/components/schemas/debt' }
          }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    post 'Create a new debt' do
      tags 'Debts'
      operationId 'createDebt'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :debt, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Car Loan' },
          amount: { type: :number, example: 15000.00 },
          creditor: { type: :string, example: 'ABC Bank' },
          description: { type: :string, example: 'Monthly car loan payment' },
          due_date: { type: :string, format: :date, example: '2026-12-31' },
          status: { type: :string, enum: %w[pending paid overdue], example: 'pending' },
          debt_type: { type: :string, example: 'loan' },
          interest_rate: { type: :number, example: 5.5 },
          is_recurring: { type: :boolean, example: true }
        },
        required: %w[title amount creditor due_date debt_type]
      }

      response '201', 'Debt created' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/debt' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  path '/api/v1/debts/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Debt ID'

    get 'Get debt details' do
      tags 'Debts'
      operationId 'getDebt'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Debt details' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/debt' }
        }
        run_test!
      end

      response '404', 'Debt not found' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    put 'Update a debt' do
      tags 'Debts'
      operationId 'updateDebt'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :debt, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          amount: { type: :number },
          creditor: { type: :string },
          description: { type: :string },
          due_date: { type: :string, format: :date },
          status: { type: :string, enum: %w[pending paid overdue] },
          debt_type: { type: :string },
          interest_rate: { type: :number },
          is_recurring: { type: :boolean }
        }
      }

      response '200', 'Debt updated' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/debt' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    delete 'Delete a debt' do
      tags 'Debts'
      operationId 'deleteDebt'
      security [bearer_auth: []]

      response '204', 'Debt deleted' do
        run_test!
      end

      response '404', 'Debt not found' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end
end
