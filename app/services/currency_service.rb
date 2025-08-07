class CurrencyService
  include HTTParty
  base_uri 'https://api.exchangerate-api.com/v4'
  
  CACHE_DURATION = 1.hour
  
  def self.convert_amount(amount, from_currency, to_currency)
    return amount if from_currency == to_currency
    
    rate = get_exchange_rate(from_currency, to_currency)
    (amount * rate).round(2)
  end
  
  def self.get_exchange_rate(from_currency, to_currency)
    return 1.0 if from_currency == to_currency
    
    cache_key = "exchange_rate_#{from_currency}_#{to_currency}"
    
    Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
      response = get("/latest/#{from_currency}")
      
      if response.success?
        response.parsed_response.dig('rates', to_currency) || 1.0
      else
        Rails.logger.error "Failed to fetch exchange rate: #{response.code}"
        1.0 # Fallback to 1:1 rate
      end
    rescue => e
      Rails.logger.error "Exchange rate API error: #{e.message}"
      1.0 # Fallback to 1:1 rate
    end
  end
  
  def self.supported_currencies
    Rails.cache.fetch('supported_currencies', expires_in: 24.hours) do
      {
        'USD' => { name: 'US Dollar', symbol: '$', code: 'USD' },
        'EUR' => { name: 'Euro', symbol: '€', code: 'EUR' },
        'GBP' => { name: 'British Pound', symbol: '£', code: 'GBP' },
        'JPY' => { name: 'Japanese Yen', symbol: '¥', code: 'JPY' },
        'CAD' => { name: 'Canadian Dollar', symbol: 'C$', code: 'CAD' },
        'AUD' => { name: 'Australian Dollar', symbol: 'A$', code: 'AUD' },
        'CHF' => { name: 'Swiss Franc', symbol: 'CHF', code: 'CHF' },
        'CNY' => { name: 'Chinese Yuan', symbol: '¥', code: 'CNY' },
        'KES' => { name: 'Kenyan Shilling', symbol: 'KSh', code: 'KES' },
        'NGN' => { name: 'Nigerian Naira', symbol: '₦', code: 'NGN' },
        'ZAR' => { name: 'South African Rand', symbol: 'R', code: 'ZAR' },
        'UGX' => { name: 'Ugandan Shilling', symbol: 'USh', code: 'UGX' },
        'TZS' => { name: 'Tanzanian Shilling', symbol: 'TSh', code: 'TZS' },
        'RWF' => { name: 'Rwandan Franc', symbol: 'RF', code: 'RWF' },
        'ETB' => { name: 'Ethiopian Birr', symbol: 'Br', code: 'ETB' },
        'GHS' => { name: 'Ghanaian Cedi', symbol: '₵', code: 'GHS' }
      }
    end
  end
  
  def self.format_money(amount, currency_code)
    currency_info = supported_currencies[currency_code]
    return amount.to_s unless currency_info
    
    {
      amount: amount,
      formatted: "#{currency_info[:symbol]}#{format_number(amount)}",
      currency_code: currency_code,
      currency_symbol: currency_info[:symbol],
      currency_name: currency_info[:name]
    }
  end
  
  private
  
  def self.format_number(amount)
    # Format number with commas for thousands
    sprintf("%.2f", amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
