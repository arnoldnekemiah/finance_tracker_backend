# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Support Messages API', type: :request do
  path '/api/v1/support_messages' do
    get 'List user support messages' do
      tags 'Support'
      operationId 'listSupportMessages'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'List of support messages' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: { '$ref' => '#/components/schemas/support_message' }
          }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    post 'Submit a support message' do
      tags 'Support'
      operationId 'createSupportMessage'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :support_message, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: 'user@example.com' },
          display_name: { type: :string, example: 'John Doe' },
          message_type: { type: :string, example: 'bug_report', description: 'e.g. bug_report, feature_request, general' },
          message: { type: :string, example: 'I found a bug when...' },
          app_version: { type: :string, example: '1.2.0' },
          build_number: { type: :string, example: '42' },
          platform: { type: :string, example: 'ios' }
        },
        required: %w[message message_type]
      }

      response '201', 'Support message submitted' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/support_message' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end
end
