# frozen_string_literal: true

FactoryBot.define do
  factory :support_message do
    association :user
    subject { Faker::Lorem.sentence }
    message { Faker::Lorem.paragraph }
    status { 'new' }
  end
end
