FactoryBot.define do
  factory :broker_customer_receivable_contact do
    broker_customer { nil }
    contact { nil }
    primary { false }
  end
end
