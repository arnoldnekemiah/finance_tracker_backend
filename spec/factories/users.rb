FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password" }
    first_name { "John" }
    last_name { "Doe" }
  end
end
