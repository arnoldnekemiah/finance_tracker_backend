# frozen_string_literal: true

FactoryBot.define do
  factory :saving_goal do
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
    target_amount { Faker::Commerce.price(range: 1000.0..10000.0) }
    current_amount { Faker::Commerce.price(range: 0.0..500.0) }
    target_date { 1.year.from_now }
    notes { Faker::Lorem.sentence }
  end
end
