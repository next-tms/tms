# == Schema Information
#
# Table name: shipments
#
# @!attribute id
#   @return [Integer]
# @!attribute bol
#   @return [String]
# @!attribute bol_notes
#   @return [String]
# @!attribute booked_at
#   @return [Time]
# @!attribute broker_bol_shipment_fingerprint
#   @return [String]
# @!attribute broker_dispatch_sheet_shipment_fingerprint
#   @return [String]
# @!attribute broker_notes
#   @return [String]
# @!attribute broker_quote_shipment_fingerprint
#   @return [String]
# @!attribute canceled_at
#   @return [Time]
# @!attribute carrier_charge_cents
#   @return [Integer]
# @!attribute carrier_charge_currency
#   @return [String]
# @!attribute carrier_cost_cents
#   @return [Integer]
# @!attribute carrier_cost_currency
#   @return [String]
# @!attribute customer_notes
#   @return [String]
# @!attribute customer_reference
#   @return [String]
# @!attribute delivery_eta_on
#   @return [Date]
# @!attribute delivered_at
#   @return [Time]
# @!attribute delivery_appointment_at
#   @return [Time]
# @!attribute delivery_appointment_on
#   @return [Date]
# @!attribute delivery_hours_end_at
#   @return [String]
# @!attribute delivery_hours_start_at
#   @return [String]
# @!attribute departed_origin_terminal_at
#   @return [Time]
# @!attribute dispatched_at
#   @return [Time]
# @!attribute lift_gate_delivery
#   @return [Boolean]
# @!attribute lift_gate_pickup
#   @return [Boolean]
# @!attribute load
#   @return [Integer]
# @!attribute lost_on
#   @return [Date]
# @!attribute notify
#   @return [Boolean]
# @!attribute out_for_delivery_at
#   @return [Time]
# @!attribute pending_appointment_since
#   @return [Date]
# @!attribute picked_up
#   @return [Boolean]
# @!attribute picked_up_at
#   @return [Time]
# @!attribute pickup_confirmation
#   @return [String]
# @!attribute pickup_driver_assigned_at
#   @return [Time]
# @!attribute pickup_eta_at
#   @return [String]
# @!attribute pickup_hours_end_at
#   @return [String]
# @!attribute pickup_hours_start_at
#   @return [String]
# @!attribute pickup_on
#   @return [Date]
# @!attribute priority
#   @return [Integer]
# @!attribute pro
#   @return [String]
# @!attribute promised_delivery_by
#   @return [Time]
# @!attribute public_notes
#   @return [String]
# @!attribute quote_only
#   @return [Boolean]
# @!attribute quoted_delivery_by
#   @return [Time]
# @!attribute receiver_available_at
#   @return [Time]
# @!attribute receiver_contact_email
#   @return [String]
# @!attribute receiver_contact_name
#   @return [String]
# @!attribute receiver_contact_phone
#   @return [String]
# @!attribute receiver_name
#   @return [String]
# @!attribute receiver_unavailable_at
#   @return [Time]
# @!attribute shipper_available_at
#   @return [Time]
# @!attribute shipper_bol
#   @return [String]
# @!attribute shipper_contact_email
#   @return [String]
# @!attribute shipper_contact_name
#   @return [String]
# @!attribute shipper_contact_phone
#   @return [String]
# @!attribute shipper_name
#   @return [String]
# @!attribute shipper_reference
#   @return [String]
# @!attribute shipper_unavailable_at
#   @return [Time]
# @!attribute total_charges_cents
#   @return [Integer]
# @!attribute total_charges_currency
#   @return [String]
# @!attribute total_cost_cents
#   @return [Integer]
# @!attribute total_cost_currency
#   @return [String]
# @!attribute tracking_carrier_pickup_confirmation
#   @return [String]
# @!attribute tracking_carrier_pro
#   @return [String]
# @!attribute truckload
#   @return [Boolean]
# @!attribute value_cents
#   @return [Integer]
# @!attribute value_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute applied_rate_id
#   @return []
# @!attribute broker_carrier_id
#   @return [Integer]
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return [Integer]
# @!attribute load_id
#   @return [Integer]
# @!attribute quote_id
#   @return [String]
# @!attribute receiver_address_id
#   @return []
# @!attribute shipper_address_id
#   @return []
# @!attribute tracking_carrier_id
#   @return []
# @!attribute updated_by_id
#   @return []
#
# Indexes
#
#  index_shipments_on_applied_rate_id        (applied_rate_id)
#  index_shipments_on_broker_customer_id     (broker_customer_id)
#  index_shipments_on_broker_id_and_load_id  (broker_id,load_id) UNIQUE
#  index_shipments_on_broker_notes           (broker_notes)
#  index_shipments_on_receiver_address_id    (receiver_address_id)
#  index_shipments_on_shipper_address_id     (shipper_address_id)
#  index_shipments_on_tracking_carrier_id    (tracking_carrier_id)
#  index_shipments_on_updated_by_id          (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (applied_rate_id => rates.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (receiver_address_id => addresses.id)
#  fk_rails_...  (shipper_address_id => addresses.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class ShipmentSerializer < ActiveModel::Serializer
  attributes :id, :fingerprint, :shipper_name, :shipper_reference, :customer_reference, :pro, :picked_up,
             :receiver_name, :shipper_contact_name, :shipper_contact_phone, :shipper_contact_email, :receiver_contact_name, :receiver_contact_phone, :receiver_contact_email, :shipper_address, :receiver_address, :pickup_on, :delivered_at, :created_at, :updated_at, :delivery_eta_on, :total_charges_cents, :total_charges_currency, :picked_up_at, :out_for_delivery_at, :value_cents, :value_currency, :bol_notes, :canceled_at, :promised_delivery_by, :truckload, :pending_appointment_since, :delivery_appointment_at, :delivery_appointment_on, :carrier, :pickup_hours_start_at, :pickup_hours_end_at, :delivery_hours_start_at, :delivery_hours_end_at, :applied_rate, :items, :rates

  def applied_rate
    ActiveModel::SerializableResource.new(object.applied_rate)
  end

  def carrier
    ActiveModel::SerializableResource.new(object.carrier)
  end

  def items
    ActiveModel::SerializableResource.new(object.items, each_serializer: ItemSerializer)
  end

  def rates
    ActiveModel::SerializableResource.new(object.rates, each_serializer: RateSerializer)
  end

  def receiver_address
    ActiveModel::SerializableResource.new(object.receiver_address)
  end

  def shipper_address
    ActiveModel::SerializableResource.new(object.shipper_address)
  end

  def id
    object.load_id
  end
end
