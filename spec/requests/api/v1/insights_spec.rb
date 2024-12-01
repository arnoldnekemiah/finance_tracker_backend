require 'swagger_helper'

RSpec.describe 'Insights API', type: :request do
  path '/api/v1/insights/overview' do
    get 'Get monthly overview' do
      tags 'Insights'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'overview data retrieved' do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                total_income: { type: :number },
                total_expenses: { type: :number },
                top_categories: { 
                  type: :object,
                  additionalProperties: { type: :number }
                },
                monthly_trend: { type: :number }
              }
            }
          }
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        run_test!
      end
    end
  end

  path '/api/v1/insights/spending_by_category' do
    get 'Get spending by category' do
      tags 'Insights'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'category data retrieved' do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              additionalProperties: { type: :number }
            }
          }
        run_test!
      end
    end
  end

  path '/api/v1/insights/weekly_trends' do
    get 'Get weekly spending trends' do
      tags 'Insights'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'weekly trends retrieved' do
        schema type: :object,
          properties: {
            data: {
              type: :object,
              additionalProperties: { type: :number }
            }
          }
        run_test!
      end
    end
  end
end 