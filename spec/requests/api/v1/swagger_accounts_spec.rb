# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Accounts API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{auth_token(user)}" }

  path '/api/v1/accounts' do
    get 'List all active accounts' do
      tags 'Accounts'
      operationId 'listAccounts'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'List of active accounts' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: { '$ref' => '#/components/schemas/account' }
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

    post 'Create a new account' do
      let(:account) { { name: 'My Account', account_type: 'regular', balance: '1000.00', currency: 'USD' } }
      tags 'Accounts'
      operationId 'createAccount'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :account, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Checking Account' },
          account_type: { type: :string, example: 'checking', description: 'e.g. checking, savings, credit_card, cash, investment' },
          bank_name: { type: :string, example: 'Chase Bank' },
          balance: { type: :number, example: 1000.00 },
          currency: { type: :string, example: 'USD' },
          account_number: { type: :string, example: '****1234' },
          is_active: { type: :boolean, example: true }
        },
        required: %w[name account_type]
      }

      response '201', 'Account created' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/account' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        let(:account) { { name: '' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  path '/api/v1/accounts/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Account ID'

    let(:id) { create(:account, user: user).id }

    get 'Get account details' do
      tags 'Accounts'
      operationId 'getAccount'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Account details' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/account' }
        }
        run_test!
      end

      response '404', 'Account not found' do
        let(:id) { 0 }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    put 'Update an account' do
      let(:account) { { name: 'Updated Account' } }
      tags 'Accounts'
      operationId 'updateAccount'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :account, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          account_type: { type: :string },
          bank_name: { type: :string },
          balance: { type: :number },
          currency: { type: :string },
          account_number: { type: :string },
          is_active: { type: :boolean }
        }
      }

      response '200', 'Account updated' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/account' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        let(:account) { { account_type: 'invalid_type' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    delete 'Delete (deactivate) an account' do
      tags 'Accounts'
      operationId 'deleteAccount'
      security [bearer_auth: []]

      response '204', 'Account deactivated' do
        run_test!
      end

      response '404', 'Account not found' do
        let(:id) { 0 }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end
end
