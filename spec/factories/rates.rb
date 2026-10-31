# == Schema Information
#
# Table name: rates
#
# @!attribute id
#   @return []
# @!attribute api_errors
#   @return [Hash]
# @!attribute api_request
#   @return [String]
# @!attribute api_response
#   @return [String]
# @!attribute breakdown
#   @return [Hash]
# @!attribute cost_cents
#   @return [Integer]
# @!attribute cost_currency
#   @return [String]
# @!attribute declared_freight_classes
#   @return [Boolean]
# @!attribute expires_at
#   @return [Time]
# @!attribute freight_kit_service_type
#   @return [String]
# @!attribute incomplete
#   @return [Boolean]
# @!attribute reference
#   @return [String]
# @!attribute shipment_fingerprint
#   @return [String]
# @!attribute source
#   @return [String]
# @!attribute transit_days
#   @return [Integer]
# @!attribute uid
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute broker_customer_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute tracking_carrier_id
#   @return []
#
# Indexes
#
#  index_rates_on_broker_carrier_id         (broker_carrier_id)
#  index_rates_on_broker_customer_id        (broker_customer_id)
#  index_rates_on_freight_kit_service_type  (freight_kit_service_type)
#  index_rates_on_shipment_id               (shipment_id)
#  index_rates_on_tracking_carrier_id       (tracking_carrier_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#
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
