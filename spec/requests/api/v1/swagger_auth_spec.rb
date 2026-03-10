# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Authentication API', type: :request do
  # ── Sign Up ────────────────────────────────────────────────────────────────
  path '/api/v1/auth/signup' do
    post 'Create a new user account' do
      let(:body) do
        {
          email: Faker::Internet.unique.email,
          password: 'Password1!',
          password_confirmation: 'Password1!',
          first_name: 'John',
          last_name: 'Doe'
        }
      end
      tags 'Authentication'
      operationId 'signup'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: 'user@example.com' },
          password: { type: :string, example: 'Password123!' },
          password_confirmation: { type: :string, example: 'Password123!' },
          first_name: { type: :string, example: 'John' },
          last_name: { type: :string, example: 'Doe' },
          currency: { type: :string, example: 'USD' }
        },
        required: %w[email password password_confirmation first_name last_name]
      }

      response '201', 'Account created successfully' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              user: { '$ref' => '#/components/schemas/user' },
              token: { type: :string, description: 'JWT authentication token' }
            }
          }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        let(:body) { { email: 'not-an-email' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Login ──────────────────────────────────────────────────────────────────
  path '/api/v1/auth/login' do
    post 'Sign in with email and password' do
      let(:user) { create(:user) }
      let(:body) { { email: user.email, password: 'Password1!' } }
      tags 'Authentication'
      operationId 'login'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: 'user@example.com' },
          password: { type: :string, example: 'Password123!' }
        },
        required: %w[email password]
      }

      response '200', 'Login successful' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              user: { '$ref' => '#/components/schemas/user' },
              token: { type: :string, description: 'JWT authentication token' }
            }
          }
        }
        run_test!
      end

      response '401', 'Invalid credentials or deactivated account' do
        let(:body) { { email: user.email, password: 'WrongPassword!' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Google OAuth ───────────────────────────────────────────────────────────
  path '/api/v1/auth/google' do
    post 'Authenticate via Google OAuth' do
      let(:body) { { email: Faker::Internet.unique.email, uid: SecureRandom.uuid, first_name: 'John', last_name: 'Doe' } }
      tags 'Authentication'
      operationId 'googleAuth'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email },
          first_name: { type: :string },
          last_name: { type: :string },
          uid: { type: :string, description: 'Google user ID' },
          photo_url: { type: :string, nullable: true }
        },
        required: %w[email uid]
      }

      response '200', 'Google authentication successful' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              user: { '$ref' => '#/components/schemas/user' },
              token: { type: :string }
            }
          }
        }
        run_test!
      end

      response '422', 'Google authentication failed' do
        let(:body) { { email: 'invalid' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Logout ─────────────────────────────────────────────────────────────────
  path '/api/v1/auth/logout' do
    delete 'Sign out and invalidate JWT token' do
      let(:user) { create(:user) }
      let(:Authorization) { "Bearer #{auth_token(user)}" }
      tags 'Authentication'
      operationId 'logout'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Logged out successfully' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              message: { type: :string, example: 'Logged out successfully' }
            }
          }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Current User ───────────────────────────────────────────────────────────
  path '/api/v1/auth/me' do
    get 'Get current authenticated user profile' do
      let(:user) { create(:user) }
      let(:Authorization) { "Bearer #{auth_token(user)}" }
      tags 'Authentication'
      operationId 'getCurrentUser'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Current user data' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/user' }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Forgot Password ────────────────────────────────────────────────────────
  path '/api/v1/auth/forgot_password' do
    post 'Request password reset OTP via email' do
      let(:user) { create(:user) }
      let(:body) { { email: user.email } }
      tags 'Authentication'
      operationId 'forgotPassword'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email, example: 'user@example.com' }
        },
        required: %w[email]
      }

      response '200', 'OTP sent (always returns success for security)' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              message: { type: :string, example: 'If an account exists with that email, a reset code has been sent.' }
            }
          }
        }
        run_test!
      end
    end
  end

  # ── Verify OTP ─────────────────────────────────────────────────────────────
  path '/api/v1/auth/verify_otp' do
    post 'Verify the password reset OTP' do
      tags 'Authentication'
      operationId 'verifyOtp'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email },
          otp: { type: :string, description: '6-digit OTP code' }
        },
        required: %w[email otp]
      }

      let(:user) { create(:user) }

      response '200', 'OTP verified, reset token returned' do
        before { user.generate_reset_otp! }
        let(:body) { { email: user.email, otp: user.reload.reset_otp } }
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              message: { type: :string },
              reset_token: { type: :string, description: 'JWT token to use for password reset' }
            }
          }
        }
        run_test!
      end

      response '422', 'Invalid or expired OTP' do
        let(:body) { { email: user.email, otp: '000000' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  # ── Reset Password ────────────────────────────────────────────────────────
  path '/api/v1/auth/reset_password' do
    post 'Reset password using reset token' do
      let(:user) { create(:user) }
      let(:reset_token) { JwtService.encode(user.id, exp: 15.minutes.from_now) }
      let(:body) { { token: reset_token, password: 'NewPassword1!', password_confirmation: 'NewPassword1!' } }
      tags 'Authentication'
      operationId 'resetPassword'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string, description: 'Reset token from verify_otp' },
          password: { type: :string, example: 'NewPassword123!' },
          password_confirmation: { type: :string, example: 'NewPassword123!' }
        },
        required: %w[token password password_confirmation]
      }

      response '200', 'Password reset successfully' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :object,
            properties: {
              message: { type: :string, example: 'Password has been reset successfully' }
            }
          }
        }
        run_test!
      end

      response '422', 'Reset failed' do
        let(:body) { { token: 'invalid_token', password: '', password_confirmation: '' } }
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end
end
