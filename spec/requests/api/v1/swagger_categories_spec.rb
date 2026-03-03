# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Categories API', type: :request do
  path '/api/v1/categories' do
    get 'List all categories' do
      tags 'Categories'
      operationId 'listCategories'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'List of categories' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: {
            type: :array,
            items: { '$ref' => '#/components/schemas/category' }
          }
        }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    post 'Create a new category' do
      tags 'Categories'
      operationId 'createCategory'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :category, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Groceries' },
          icon: { type: :string, example: '🛒' },
          color: { type: :string, example: '#4CAF50' },
          transaction_type: { type: :string, enum: %w[income expense], example: 'expense' },
          parent_category_id: { type: :integer, nullable: true, description: 'ID of parent category for sub-categories' }
        },
        required: %w[name transaction_type]
      }

      response '201', 'Category created' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/category' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end

  path '/api/v1/categories/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Category ID'

    get 'Get category details' do
      tags 'Categories'
      operationId 'getCategory'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'Category details' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/category' }
        }
        run_test!
      end

      response '404', 'Category not found' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    put 'Update a category' do
      tags 'Categories'
      operationId 'updateCategory'
      security [bearer_auth: []]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :category, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          icon: { type: :string },
          color: { type: :string },
          transaction_type: { type: :string, enum: %w[income expense] },
          parent_category_id: { type: :integer, nullable: true }
        }
      }

      response '200', 'Category updated' do
        schema type: :object, properties: {
          status: { type: :string, example: 'success' },
          data: { '$ref' => '#/components/schemas/category' }
        }
        run_test!
      end

      response '422', 'Validation errors' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end

    delete 'Delete a category' do
      tags 'Categories'
      operationId 'deleteCategory'
      security [bearer_auth: []]

      response '204', 'Category deleted' do
        run_test!
      end

      response '404', 'Category not found' do
        schema '$ref' => '#/components/schemas/error_response'
        run_test!
      end
    end
  end
end
