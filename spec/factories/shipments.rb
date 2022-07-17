# frozen_string_literal: true

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
# @!attribute delivered_at
#   @return [Time]
# @!attribute delivery_appointment_at
#   @return [Time]
# @!attribute delivery_appointment_on
#   @return [Date]
# @!attribute delivery_eta_on
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
# @!attribute created_by_id
#   @return []
# @!attribute dispatcher_id
#   @return []
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
#  index_shipments_on_created_by_id          (created_by_id)
#  index_shipments_on_dispatcher_id          (dispatcher_id)
#  index_shipments_on_receiver_address_id    (receiver_address_id)
#  index_shipments_on_shipper_address_id     (shipper_address_id)
#  index_shipments_on_tracking_carrier_id    (tracking_carrier_id)
#  index_shipments_on_updated_by_id          (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (applied_rate_id => rates.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (dispatcher_id => users.id)
#  fk_rails_...  (receiver_address_id => addresses.id)
#  fk_rails_...  (shipper_address_id => addresses.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#  fk_rails_...  (updated_by_id => users.id)
#
FactoryBot.define do
  factory :shipment do
    broker { create(:broker) }
    broker_carrier_id { 1 }
    shipper_name { 'MyString' }
    shipper_reference { 'MyString' }
    customer_reference { 'MyString' }
    pro { 'MyString' }
    pickup_confirmation { 'MyString' }
    picked_up { false }
    priority { 1 }
    shipper_unavailable_at { '2022-07-04 19:26:38' }
    receiver_available_at { '2022-07-04 19:26:38' }
    receiver_unavailable_at { '2022-07-04 19:26:38' }
    load {}
    receiver_name { 'MyString' }
    shipper_contact_name { 'MyString' }
    shipper_contact_phone { 'MyString' }
    shipper_contact_email { 'MyString' }
    receiver_contact_name { 'MyString' }
    receiver_contact_phone { 'MyString' }
    receiver_contact_email { 'MyString' }
    shipper_bol { 'MyString' }
    shipper_address { create(:address) }
    receiver_address { create(:address) }
    bol { 'MyString' }
    pickup_on { '2022-07-04' }
    lift_gate_delivery { false }
    notify { false }
    lift_gate_pickup { false }
    delivered_at { '2022-07-04 19:26:38' }
    updated_at { '2022-07-04 19:26:38' }
    delivery_eta_on { '2022-07-04' }
    total_charges_cents { 1 }
    total_charges_currency { 'MyString' }
    total_cost_cents { 1 }
    total_cost_currency { 'MyString' }
    quote_id { 'MyString' }
    picked_up_at { '2022-07-04 19:26:38' }
    dispatched_at { '2022-07-04 19:26:38' }
    shipper_available_at { '2022-07-04 19:26:38' }
    out_for_delivery_at { '2022-07-04 19:26:38' }
    load_id { 1 }
    value_cents { 1 }
    value_currency { 'MyString' }
    bol_notes { 'MyText' }
    carrier_cost_cents { 1 }
    carrier_cost_currency { 'MyString' }
    broker_notes { 'MyText' }
    customer_notes { 'MyText' }
    carrier_charge_cents { 1 }
    carrier_charge_currency { 'MyString' }
    canceled_at { '2022-07-04 19:26:38' }
    broker_customer_id {}
    quoted_delivery_by { '2022-07-04 19:26:38' }
    promised_delivery_by { '2022-07-04 19:26:38' }
    truckload { false }
    pending_appointment_since { '2022-07-04' }
    delivery_appointment_at { '2022-07-04 19:26:38' }
    delivery_appointment_on { '2022-07-04' }
    tracking_carrier_id {}
    tracking_carrier_pro { 'MyString' }
    tracking_carrier_pickup_confirmation { 'MyString' }
    pickup_hours_start_at { 'MyString' }
    pickup_hours_end_at { 'MyString' }
    delivery_hours_start_at { 'MyString' }
    delivery_hours_end_at { 'MyString' }
    applied_rate_id {}
    pickup_eta_at { 'MyString' }
    pickup_driver_assigned_at { '2022-07-04 19:26:38' }
    departed_origin_terminal_at { '2022-07-04 19:26:38' }
    quote_only { false }
    lost_on { '2022-07-04' }
    booked_at { '2022-07-04 19:26:38' }
    broker_bol_shipment_fingerprint { 'MyString' }
    broker_quote_shipment_fingerprint { 'MyString' }
    broker_dispatch_sheet_shipment_fingerprint { 'MyString' }
    public_notes { 'MyText' }
    created_by_id {}
    dispatcher {}

    before :build do |_shipment|
      Shipment.skip_callback(:create, :after, :notify_of_new_shipment)
    end
  end
end
