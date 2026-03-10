# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    association :user
    name { Faker::Bank.name }
    account_type { 'regular' }
    balance { Faker::Commerce.price(range: 100.0..10000.0) }
    currency { 'USD' }
    is_active { true }
  end
end
