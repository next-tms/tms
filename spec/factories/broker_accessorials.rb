FactoryBot.define do
  factory :broker_accessorial do
    broker { create(:broker) }
    accessorial { create(:accessorial) }
    name { "MyString" }
    cost { 1.5 }
    upcharge { 1.5 }
    upcharge_percent { 1.5 }
    upcharge_cents { 1 }
    upcharge_currency { "USD" }
    broker_only { false }
    code { "MyString" }
    flat_charge_cents { 1 }
    flat_charge_currency { "MyString" }
    broker_customer { create(:broker_customer) }
    fee { false }
  end
end
