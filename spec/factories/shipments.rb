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
# @!attribute broker_and_broker_customer_notes
#   @return [String]
# @!attribute broker_notes
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
# @!attribute charges_confirmed
#   @return [Boolean]
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
# @!attribute fingerprint
#   @return [String]
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
# @!attribute status
#   @return [String]
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
#  index_shipments_on_applied_rate_id      (applied_rate_id)
#  index_shipments_on_broker_customer_id   (broker_customer_id)
#  index_shipments_on_broker_notes         (broker_notes)
#  index_shipments_on_created_by_id        (created_by_id)
#  index_shipments_on_dispatcher_id        (dispatcher_id)
#  index_shipments_on_load_id              (load_id) UNIQUE
#  index_shipments_on_receiver_address_id  (receiver_address_id)
#  index_shipments_on_shipper_address_id   (shipper_address_id)
#  index_shipments_on_status               (status)
#  index_shipments_on_tracking_carrier_id  (tracking_carrier_id)
#  index_shipments_on_updated_by_id        (updated_by_id)
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
    transient do
      currency { Money.default_currency.iso_code }
    end

    sequence(:load_id)

    applied_rate_id { }
    bol { Faker::Number.number }
    bol_notes { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    booked_at { 2.weeks.ago }
    broker_carrier_id { 1 }
    broker_customer { create(:broker_customer) }
    broker_notes { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    canceled_at { nil }
    carrier_charge_cents { 1 }
    carrier_charge_currency { currency }
    carrier_cost_cents { 1 }
    carrier_cost_currency { currency }
    created_by_id { }
    customer_notes { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    customer_reference { Faker::Number.number }
    delivered_at { 1.minute.ago }
    delivery_appointment_at { 1.day.ago }
    delivery_appointment_on { 1.day.ago.to_date }
    delivery_eta_on { 2.days.ago }
    delivery_hours_end_at { '08:00' }
    delivery_hours_start_at { '17:00' }
    departed_origin_terminal_at { 13.days.ago }
    dispatched_at { 2.weeks.ago }
    lift_gate_delivery { false }
    lift_gate_pickup { false }
    lost_on { 5.minutes.ago }
    notify { [ true, false ].sample }
    out_for_delivery_at { 1.week.ago }
    pending_appointment_since { 13.days.ago }
    picked_up_at { 13.days.ago }
    pickup_confirmation { Faker::Number.number }
    pickup_driver_assigned_at { 2.weeks.ago }
    pickup_eta_at { '15:00' }
    pickup_hours_end_at { '17:00' }
    pickup_hours_start_at { '14:00' }
    pickup_on { 2.weeks.ago }
    priority { 1 }
    pro { Faker::Number.number }
    promised_delivery_by { 1.week.ago }
    public_notes { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    quote_id { Faker::Number.number }
    quote_only { [ true, false ].sample }
    quoted_delivery_by { 1.week.ago }
    receiver_address { create(:address) }
    receiver_available_at { 2.weeks.ago }
    receiver_contact_email { Faker::Internet.email }
    receiver_contact_name { Faker::Name.name }
    receiver_contact_phone { Faker::PhoneNumber.phone_number }
    receiver_name { Faker::Company.name }
    receiver_unavailable_at { '2022-07-04 19:26:38' }
    shipper_address { create(:address) }
    shipper_available_at { '2022-07-04 19:26:38' }
    shipper_bol { Faker::Number.number }
    shipper_contact_email { Faker::Internet.email }
    shipper_contact_name { Faker::Name.name }
    shipper_contact_phone { Faker::PhoneNumber.phone_number }
    shipper_name { Faker::Company.name }
    shipper_reference { Faker::Number.number }
    shipper_unavailable_at { 13.days.ago }
    total_charges_cents { Faker::Number.between(from: 100, to: 5_000).ceil }
    total_charges_currency { currency }
    total_cost_cents { Faker::Number.between(from: 100, to: 5_000).ceil }
    total_cost_currency { currency }
    truckload { [ true, false ].sample }
    value_cents { Faker::Number.between(from: 100, to: 5_000).ceil }
    value_currency { currency }

    after(:build) do |record|
      user = build(:broker_user)
      user.contact = build(:contact, companyable: nil)
      user.contact.add_role(:dispatch)

      record.discussion = record.build_discussion
      record.dispatcher = user
    end

    before(:build) { Shipment.skip_callback(:create, :after, :notify_of_new_shipment) }
    after(:build) { Shipment.set_callback(:create, :after, :notify_of_new_shipment) }

    trait :with_broker_accessorials do
      broker_accessorials do
        [
          association(
            :broker_accessorial,
            broker: broker_customer.broker,
            broker_customer:,
            flat_charge_currency: currency,
            upcharge_currency: currency,
          )
        ]
      end
    end

    trait :with_items do
      items { [ association(:item, shipment: instance, strategy: :build) ] }
    end
  end
end
