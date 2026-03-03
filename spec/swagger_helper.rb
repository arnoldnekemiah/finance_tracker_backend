# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Accountanta Finance Tracker API',
        version: 'v1',
        description: 'RESTful API for the Accountanta personal finance tracking application. Manage accounts, transactions, budgets, debts, saving goals, and more.',
        contact: {
          name: 'API Support'
        }
      },
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'JWT token obtained from /api/v1/auth/login or /api/v1/auth/signup'
          }
        },
        schemas: {
          error_response: {
            type: :object,
            properties: {
              status: { type: :string, example: 'error' },
              error: { type: :string, example: 'Error message' }
            }
          },
          success_response: {
            type: :object,
            properties: {
              status: { type: :string, example: 'success' },
              data: { type: :object }
            }
          },
          user: {
            type: :object,
            properties: {
              id: { type: :integer },
              email: { type: :string, format: :email },
              first_name: { type: :string },
              last_name: { type: :string },
              currency: { type: :string, example: 'USD' },
              preferred_currency: { type: :string, example: 'USD' },
              timezone: { type: :string, example: 'UTC' },
              photo_url: { type: :string, nullable: true },
              is_admin: { type: :boolean },
              is_active: { type: :boolean },
              provider: { type: :string, nullable: true },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            }
          },
          account: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              account_type: { type: :string },
              bank_name: { type: :string, nullable: true },
              balance: { type: :string, example: '1000.00' },
              currency: { type: :string, example: 'USD' },
              description: { type: :string, nullable: true },
              is_active: { type: :boolean },
              account_number_masked: { type: :string, nullable: true },
              formatted_balance: { type: :string },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            }
          },
          category: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              icon: { type: :string, nullable: true },
              color: { type: :string, nullable: true },
              transaction_type: { type: :string, enum: %w[income expense] }
            }
          },
          transaction: {
            type: :object,
            properties: {
              id: { type: :integer },
              amount: { type: :string },
              original_amount: { type: :string, nullable: true },
              original_currency: { type: :string, example: 'USD' },
              transaction_type: { type: :string, enum: %w[income expense transfer] },
              category_id: { type: :integer, nullable: true },
              category_name: { type: :string, nullable: true },
              date: { type: :string, format: :'date-time' },
              description: { type: :string, nullable: true },
              from_account_id: { type: :integer, nullable: true },
              to_account_id: { type: :integer, nullable: true },
              payment_method: { type: :string, nullable: true },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            }
          },
          budget: {
            type: :object,
            properties: {
              id: { type: :integer },
              category: { '$ref' => '#/components/schemas/category' },
              limit: { type: :string },
              spent: { type: :string },
              start_date: { type: :string, format: :'date-time' },
              end_date: { type: :string, format: :'date-time' },
              period: { type: :string },
              percentage_used: { type: :number },
              remaining_amount: { type: :string },
              over_budget: { type: :boolean },
              days_remaining: { type: :integer }
            }
          },
          debt: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              amount: { type: :string },
              creditor: { type: :string },
              description: { type: :string, nullable: true },
              due_date: { type: :string, format: :date },
              status: { type: :string, enum: %w[pending paid overdue] },
              debt_type: { type: :string },
              interest_rate: { type: :string, nullable: true },
              is_recurring: { type: :boolean },
              recurring_period: { type: :string, nullable: true },
              overdue: { type: :boolean },
              days_until_due: { type: :integer },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            }
          },
          saving_goal: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              target_amount: { type: :string },
              current_amount: { type: :string },
              target_date: { type: :string, format: :'date-time' },
              notes: { type: :string, nullable: true },
              progress_percentage: { type: :number },
              remaining_amount: { type: :string },
              achieved: { type: :boolean },
              days_remaining: { type: :integer },
              overdue: { type: :boolean },
              monthly_savings_needed: { type: :string },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            }
          },
          support_message: {
            type: :object,
            properties: {
              id: { type: :integer },
              email: { type: :string },
              display_name: { type: :string },
              message_type: { type: :string },
              message: { type: :string },
              status: { type: :string },
              app_version: { type: :string, nullable: true },
              build_number: { type: :string, nullable: true },
              platform: { type: :string, nullable: true },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            }
          },
          pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              total_pages: { type: :integer },
              total_count: { type: :integer },
              per_page: { type: :integer }
            }
          }
        }
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Local development'
        },
        {
          url: 'https://accountanta-api.onrender.com',
          description: 'Production (Render)'
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
