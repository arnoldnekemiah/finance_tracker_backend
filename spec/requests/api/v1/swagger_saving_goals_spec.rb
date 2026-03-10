# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Saving Goals API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{auth_token(user)}" }

  path '/api/v1/saving_goals' do
    get 'List all saving goals' do
      tags 'Saving Goals'
      operationId 'listSavingGoals'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'List of saving goals' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: {
              type: :array,
              items: { '$ref' => '#/components/schemas/saving_goal' }
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

    post 'Create a new saving goal' do
      let(:saving_goal) do
        {
          title: 'Emergency Fund',
          target_amount: 10000.00,
          current_amount: 0.0,
          target_date: 1.year.from_now.iso8601,
          notes: '6 months of expenses'
        }
      end
      tags 'Saving Goals'
      operationId 'createSavingGoal'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter(name: :saving_goal, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Emergency Fund' },
          target_amount: { type: :number, example: 10000.00 },
          current_amount: { type: :number, example: 2500.00 },
          target_date: { type: :string, format: :'date-time', example: '2026-12-31T00:00:00Z' },
          notes: { type: :string, example: '6 months of expenses' }
        },
        required: %w[title target_amount]
      })

      response '201', 'Saving goal created' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: { '$ref' => '#/components/schemas/saving_goal' }
          }
        )
        run_test!
      end

      response '422', 'Validation errors' do
        let(:saving_goal) { { title: '' } }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end
  end

  path '/api/v1/saving_goals/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Saving Goal ID'

    let(:id) { create(:saving_goal, user: user).id }

    get 'Get saving goal details' do
      tags 'Saving Goals'
      operationId 'getSavingGoal'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Saving goal details' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: { '$ref' => '#/components/schemas/saving_goal' }
          }
        )
        run_test!
      end

      response '404', 'Saving goal not found' do
        let(:id) { 0 }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end

    put 'Update a saving goal' do
      let(:saving_goal) { { current_amount: 500.00 } }
      tags 'Saving Goals'
      operationId 'updateSavingGoal'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter(name: :saving_goal, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          target_amount: { type: :number },
          current_amount: { type: :number },
          target_date: { type: :string, format: :'date-time' },
          notes: { type: :string }
        }
      })

      response '200', 'Saving goal updated' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: { '$ref' => '#/components/schemas/saving_goal' }
          }
        )
        run_test!
      end

      response '422', 'Validation errors' do
        let(:saving_goal) { { target_amount: -1 } }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end

    delete 'Delete a saving goal' do
      tags 'Saving Goals'
      operationId 'deleteSavingGoal'
      security [bearer_auth: []]

      response '204', 'Saving goal deleted' do
        run_test!
      end

      response '404', 'Saving goal not found' do
        let(:id) { 0 }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end
  end
end
