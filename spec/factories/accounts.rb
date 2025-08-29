FactoryBot.define do
  factory :account do
    name { "Test Account" }
    account_type { "regular" }
    balance_cents { 100000 }
    user
  end
end
