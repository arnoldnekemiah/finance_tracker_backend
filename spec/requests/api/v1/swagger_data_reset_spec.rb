# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Data Reset API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{auth_token(user)}" }

  # ── Start Afresh ───────────────────────────────────────────────────────────
  path '/api/v1/data/start_afresh' do
    post 'Reset financial data (keep accounts & categories)' do
      tags 'Data Management'
      operationId 'startAfresh'
      security [bearer_auth: []]
      produces 'application/json'
      description 'Deletes all transactions, budgets, debts, saving goals, and support messages. Resets account balances to 0. Preserves accounts and categories.'

      response '200', 'Data reset successfully' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: {
              type: :object,
              properties: {
                message: { type: :string, example: 'All financial data has been reset. Your account and categories are preserved.' }
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

  # ── Delete All ─────────────────────────────────────────────────────────────
  path '/api/v1/data/delete_all' do
    post 'Delete all user data' do
      tags 'Data Management'
      operationId 'deleteAllData'
      security [bearer_auth: []]
      produces 'application/json'
      description 'Permanently deletes all user data including accounts, categories, transactions, budgets, debts, saving goals, and support messages.'

      response '200', 'All data deleted' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: {
              type: :object,
              properties: {
                message: { type: :string, example: 'All data has been deleted.' }
              }
            }
          }
        )
        run_test!
      end
    end
  end

  # ── Reset Balances ─────────────────────────────────────────────────────────
  path '/api/v1/data/reset_balances' do
    post 'Reset all account balances to zero' do
      tags 'Data Management'
      operationId 'resetBalances'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Balances reset' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: {
              type: :object,
              properties: {
                message: { type: :string, example: 'All account balances have been reset to 0.' }
              }
            }
          }
        )
        run_test!
      end
    end
  end
end
