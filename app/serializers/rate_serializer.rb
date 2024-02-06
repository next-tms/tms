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
# @!attribute declared_freight_classes
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
class RateSerializer < ActiveModel::Serializer
  attributes :uid, :carrier, :charge, :charge_currency, :expires_at, :transit_days, :incomplete, :shipment_fingerprint

  def carrier
    ActiveModel::SerializableResource.new(object.carrier)
  end

  def charge
    object.broker_customer.carrier_charge_calculator(carrier_cost: object.cost, shipment: object.shipment).to_f
  end

  def charge_currency
    object.cost_currency
  end

  delegate :uid, to: :object
end
