class Api::V1::ExchangeRatesController < Api::BaseController
  include Authenticatable

  CACHE_TTL = 1.hour

  # GET /api/v1/exchange_rates?base=USD
  def index
    base = (params[:base] || current_user.effective_currency || 'USD').upcase
    cache_key = "exchange_rates_#{base}"

    rates_data = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      fetch_rates(base)
    end

    if rates_data
      render json: {
        status: 'success',
        data: {
          base: base,
          rates: rates_data[:rates],
          updated_at: rates_data[:updated_at]
        }
      }
    else
      render json: {
        status: 'error',
        error: 'Unable to fetch exchange rates',
        data: { base: base, rates: {}, updated_at: nil }
      }, status: :service_unavailable
    end
  end

  private

  def fetch_rates(base)
    uri = URI("https://api.exchangerate-api.com/v4/latest/#{base}")
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      body = JSON.parse(response.body)
      { rates: body['rates'], updated_at: Time.current.iso8601 }
    else
      nil
    end
  rescue => e
    Rails.logger.error "ExchangeRates fetch failed: #{e.message}"
    nil
  end
end
