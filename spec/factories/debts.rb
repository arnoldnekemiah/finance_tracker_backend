# frozen_string_literal: true

FactoryBot.define do
  factory :debt do
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
    amount { Faker::Commerce.price(range: 100.0..5000.0) }
    creditor { Faker::Company.name }
    description { Faker::Lorem.sentence }
    due_date { Faker::Date.forward(days: 30) }
    status { 'pending' }
    debt_type { 'loan' }
    is_recurring { false }
  end
end
