# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Profile API', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{auth_token(user)}" }

  # ── Update Profile ─────────────────────────────────────────────────────────
  path '/api/v1/profile' do
    put 'Update user profile' do
      let(:profile) { { first_name: 'Jane', last_name: 'Smith', currency: 'EUR' } }
      tags 'Profile'
      operationId 'updateProfile'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :profile, in: :body, schema: {
        type: :object,
        properties: {
          first_name: { type: :string, example: 'John' },
          last_name: { type: :string, example: 'Doe' },
          email: { type: :string, format: :email },
          currency: { type: :string, example: 'USD' },
          preferred_currency: { type: :string, example: 'EUR' },
          timezone: { type: :string, example: 'Africa/Nairobi' },
          photo_url: { type: :string, nullable: true }
        }
      }

      response '200', 'Profile updated' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: { '$ref' => '#/components/schemas/user' }
          }
        )
        run_test!
      end

      response '422', 'Validation errors' do
        let(:profile) { { email: 'not-an-email' } }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end
  end

  # ── Upload Photo ───────────────────────────────────────────────────────────
  path '/api/v1/profile/upload_photo' do
    post 'Upload profile photo' do
      tags 'Profile'
      operationId 'uploadProfilePhoto'
      security [bearer_auth: []]
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :photo, in: :formData, type: :file, required: false, description: 'Photo file upload'
      parameter name: :photo_url, in: :formData, type: :string, required: false, description: 'Photo URL (alternative to file upload)'

      response '200', 'Photo uploaded' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: { '$ref' => '#/components/schemas/user' }
          }
        )
        run_test!
      end

      response '422', 'No photo provided' do
        schema('$ref' => '#/components/schemas/error_response')
        run_test!
      end
    end
  end

  # ── Delete Photo ───────────────────────────────────────────────────────────
  path '/api/v1/profile/delete_photo' do
    delete 'Remove profile photo' do
      tags 'Profile'
      operationId 'deleteProfilePhoto'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Photo removed' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: { '$ref' => '#/components/schemas/user' }
          }
        )
        run_test!
      end
    end
  end

  # ── Delete Account ─────────────────────────────────────────────────────────
  path '/api/v1/profile/delete_account' do
    delete 'Permanently delete user account and all data' do
      tags 'Profile'
      operationId 'deleteUserAccount'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Account deleted' do
        schema(
          type: :object,
          properties: {
            status: { type: :string, example: 'success' },
            data: {
              type: :object,
              properties: {
                message: { type: :string, example: 'Account deleted successfully' }
              }
            }
          }
        )
        run_test!
      end
    end
  end
end
