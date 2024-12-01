require 'swagger_helper'

RSpec.describe 'Authentication API', type: :request do
  path '/signup' do
    post 'Register a new user' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: 'email' },
              password: { type: :string, minimum: 6 },
              password_confirmation: { type: :string },
              name: { type: :string },
              avatar: { type: :string }
            },
            required: ['email', 'password', 'password_confirmation']
          }
        }
      }

      response '200', 'user registered' do
        schema type: :object,
          properties: {
            status: {
              type: :object,
              properties: {
                code: { type: :integer },
                message: { type: :string }
              }
            },
            data: {
              type: :object,
              properties: {
                email: { type: :string },
                name: { type: :string },
                avatar: { type: :string }
              }
            }
          }
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            status: {
              type: :object,
              properties: {
                message: { type: :string }
              }
            }
          }
        run_test!
      end
    end
  end

  path '/login' do
    post 'Login user' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: 'email' },
              password: { type: :string }
            },
            required: ['email', 'password']
          }
        }
      }

      response '200', 'user logged in' do
        header 'Authorization', schema: { type: :string }, description: 'JWT token'
        schema type: :object,
          properties: {
            status: {
              type: :object,
              properties: {
                code: { type: :integer },
                message: { type: :string }
              }
            },
            data: {
              type: :object,
              properties: {
                email: { type: :string },
                name: { type: :string },
                avatar: { type: :string }
              }
            }
          }
        run_test!
      end

      response '401', 'invalid credentials' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        run_test!
      end
    end
  end

  path '/logout' do
    delete 'Logout user' do
      tags 'Authentication'
      security [bearer_auth: []]
      
      response '200', 'logged out successfully' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }
        run_test!
      end
    end
  end
end 