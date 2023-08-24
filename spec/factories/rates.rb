# frozen_string_literal: true

# == Schema Information
#
# Table name: rates
#
# @!attribute id
#   @return []
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
# @!attribute error_object
#   @return [String]
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
# @!attribute with_calculated_freight_classes
#   @return [Boolean]
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
    freight_kit_service_type { 'MyString' }
    error_object { 'MyString' }
    breakdown { '' }
    source { 'api' }
  end
end
