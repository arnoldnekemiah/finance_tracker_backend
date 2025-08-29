FactoryBot.define do
  factory :category do
    name { "Test Category" }
    transaction_type { "expense" }
    user
  end
end
