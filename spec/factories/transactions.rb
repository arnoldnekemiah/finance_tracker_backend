FactoryBot.define do
  factory :transaction do
    original_amount { 100 }
    original_currency { "USD" }
    transaction_type { "expense" }
    description { "Test Transaction" }
    date { Date.today }
    user
    category
    association :from_account, factory: :account
    association :to_account, factory: :account
  end
end
