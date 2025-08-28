require 'money'
require 'money/rates_store/memory'

class CustomBank < Money::Bank::VariableExchange
  def get_rate(from_currency, to_currency, _opts = {})
    CurrencyService.get_exchange_rate(from_currency, to_currency)
  end
end

Money.default_bank = CustomBank.new(Money::RatesStore::Memory.new)
