require 'swagger_helper'

RSpec.describe 'Saving Goals API', type: :request do
  path '/api/v1/saving_goals' do
    get 'Lists all saving goals' do
      tags 'Saving Goals'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'saving goals found' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  title: { type: :string },
                  target_amount: { type: :number },
                  current_amount: { type: :number },
                  target_date: { type: :string, format: 'date-time' },
                  notes: { type: :string }
                }
              }
            }
          }
        run_test!
      end
    end

    post 'Creates a saving goal' do
      tags 'Saving Goals'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :saving_goal, in: :body, schema: {
        type: :object,
        properties: {
          saving_goal: {
            type: :object,
            properties: {
              title: { type: :string },
              target_amount: { type: :number },
              current_amount: { type: :number },
              target_date: { type: :string, format: 'date-time' },
              notes: { type: :string }
            },
            required: ['title', 'target_amount', 'target_date']
          }
        }
      }

      response '201', 'saving goal created' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            title: { type: :string },
            target_amount: { type: :number },
            current_amount: { type: :number },
            target_date: { type: :string, format: 'date-time' },
            notes: { type: :string }
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

  path '/api/v1/saving_goals/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Retrieves a saving goal' do
      tags 'Saving Goals'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'saving goal found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            title: { type: :string },
            target_amount: { type: :number },
            current_amount: { type: :number },
            target_date: { type: :string, format: 'date-time' },
            notes: { type: :string }
          }
        run_test!
      end

      response '404', 'saving goal not found' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        run_test!
      end
    end

    put 'Updates a saving goal' do
      tags 'Saving Goals'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :saving_goal, in: :body, schema: {
        type: :object,
        properties: {
          saving_goal: {
            type: :object,
            properties: {
              title: { type: :string },
              target_amount: { type: :number },
              current_amount: { type: :number },
              target_date: { type: :string, format: 'date-time' },
              notes: { type: :string }
            }
          }
        }
      }

      response '200', 'saving goal updated' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            title: { type: :string },
            target_amount: { type: :number },
            current_amount: { type: :number },
            target_date: { type: :string, format: 'date-time' },
            notes: { type: :string }
          }
        run_test!
      end
    end

    delete 'Deletes a saving goal' do
      tags 'Saving Goals'
      security [bearer_auth: []]

      response '204', 'saving goal deleted' do
        run_test!
      end
    end
  end
end 