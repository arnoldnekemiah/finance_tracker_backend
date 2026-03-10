# frozen_string_literal: true

FactoryBot.define do
  factory :budget do
    association :user
    association :category
    limit { Faker::Commerce.price(range: 100.0..2000.0) }
    period { 'monthly' }
    start_date { Date.today.beginning_of_month }
    end_date { Date.today.end_of_month }
  end
end
