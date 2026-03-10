# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    association :user
    name { Faker::Commerce.department(num: 1) }
    icon { '📦' }
    color { Faker::Color.hex_color }
    transaction_type { 'expense' }

    trait :income do
      transaction_type { 'income' }
    end

    trait :expense do
      transaction_type { 'expense' }
    end
  end
end
