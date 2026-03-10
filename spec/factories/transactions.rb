# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    association :user
    association :account
    association :category
    amount { Faker::Commerce.price(range: 10.0..1000.0) }
    transaction_type { 'expense' }
    date { Faker::Time.backward(days: 30) }
    description { Faker::Lorem.sentence }
    payment_method { 'cash' }

    trait :income do
      transaction_type { 'income' }
    end

    trait :transfer do
      transaction_type { 'transfer' }
    end
  end
end
