FactoryBot.define do
  factory :upcharge_rule do
    broker_customer_id { 1 }
    packaging { create(:packaging) }
    max { 1 }
    min { 1 }
    upcharge_cents { 1 }
    upcharge_currency { 'MyString' }
    upcharge_percentage { 1.5 }
    updated_at { '2023-04-21 00:10:08' }
  end
end
