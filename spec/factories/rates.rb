# frozen_string_literal: true

FactoryBot.define do
  factory :rate do
    broker_carrier { create(:broker_carrier) }
    tracking_carrier_id { create(:carrier) }
    broker_customer { create(:broker_customer) }
    shipment { create(:shipment) }
    cost_cents { 1 }
    cost_currency { 'MyString' }
    expires_at { '2023-04-05 23:21:03' }
    reference { 'MyString' }
    api_request { 'MyText' }
    api_response { 'MyText' }
    transit_days { 1 }
    with_calculated_freight_classes { false }
    incomplete { false }
    shipment_fingerprint { 'MyString' }
    uid { 'MyString' }
    interstellar_service_type { 'MyString' }
    error_object { 'MyString' }
    breakdown { '' }
    source { 'api' }
  end
end
