FactoryBot.define do
  factory :rate do
    api_request { {} }
    api_response { {} }
    breakdown { '' }
    broker_carrier { create(:broker_carrier) }
    broker_customer { create(:broker_customer) }
    cost_cents { 1 }
    cost_currency { 'MyString' }
    declared_freight_classes { [true, false].sample }
    expires_at { '2023-04-05 23:21:03' }
    freight_kit_service_type { 'MyString' }
    incomplete { false }
    reference { 'MyString' }
    shipment { create(:shipment) }
    shipment_fingerprint { 'MyString' }
    source { 'api' }
    tracking_carrier_id { create(:carrier) }
    transit_days { 1 }
    uid { 'MyString' }
  end
end
