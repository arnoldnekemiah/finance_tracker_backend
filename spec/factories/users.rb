# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'Password1!' }
    password_confirmation { 'Password1!' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    jti { SecureRandom.uuid }
    currency { 'USD' }
    active { true }
    admin { false }

    trait :admin do
      admin { true }
    end

    trait :without_defaults do
      after(:build) do |user|
        user.define_singleton_method(:create_default_categories) {}
        user.define_singleton_method(:create_default_account) {}
      end
    end
  end
end
