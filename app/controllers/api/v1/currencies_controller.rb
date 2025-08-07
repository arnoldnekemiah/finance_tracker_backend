class Api::V1::CurrenciesController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_authorization_check

  def index
    render json: {
      status: { success: true, message: "Currencies retrieved successfully" },
      data: {
        supported_currencies: CurrencyService.supported_currencies,
        user_currency: current_user.effective_currency,
        exchange_rates: get_current_rates
      }
    }
  end

  def update_preference
    if current_user.update(currency_params)
      render json: {
        status: { success: true, message: 'Currency preference updated successfully' },
        data: { 
          preferred_currency: current_user.preferred_currency,
          currency_info: current_user.currency_info
        }
      }
    else
      render json: {
        status: { success: false, message: current_user.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
    end
  end

  def exchange_rates
    from_currency = params[:from] || current_user.effective_currency
    to_currencies = params[:to]&.split(',') || CurrencyService.supported_currencies.keys

    rates = to_currencies.map do |to_currency|
      {
        from: from_currency,
        to: to_currency,
        rate: CurrencyService.get_exchange_rate(from_currency, to_currency),
        updated_at: Time.current.iso8601
      }
    end

    render json: {
      status: { success: true, message: "Exchange rates retrieved successfully" },
      data: {
        base_currency: from_currency,
        rates: rates
      }
    }
  end

  private

  def currency_params
    params.require(:user).permit(:preferred_currency, :timezone)
  end

  def get_current_rates
    base_currency = current_user.effective_currency
    CurrencyService.supported_currencies.keys.map do |currency|
      {
        from: base_currency,
        to: currency,
        rate: CurrencyService.get_exchange_rate(base_currency, currency)
      }
    end
  end
end
