FactoryBot.define do
  factory :shipment do
    sequence(:load_id)

    applied_rate_id { nil }
    bol { Faker::Number.number }
    bol_notes { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    booked_at { 2.weeks.ago }
    broker_carrier_id { 1 }
    broker_customer { create(:broker_customer) }
    broker_notes { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    canceled_at { nil }
    carrier_charge_cents { 1 }
    carrier_charge_currency { Faker::Currency.code }
    carrier_cost_cents { 1 }
    carrier_cost_currency { Faker::Currency.code }
    created_by_id { nil }
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
    notify { [true, false].sample }
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
    quote_only { [true, false].sample }
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
    total_charges_currency { Faker::Currency.code }
    total_cost_cents { Faker::Number.between(from: 100, to: 5_000).ceil }
    total_cost_currency { Faker::Currency.code }
    truckload { [true, false].sample }
    value_cents { Faker::Number.between(from: 100, to: 5_000).ceil }
    value_currency { Faker::Currency.code }

    trait :usd do
      carrier_charge_currency { 'USD' }
      carrier_cost_currency { 'USD' }
      total_charges_currency { 'USD' }
      total_cost_currency { 'USD' }
      value_currency { 'USD' }
    end

    after(:build) do |record|
      user = build(:broker_user)
      user.contact = build(:contact, companyable: nil)
      user.contact.add_role(:dispatch)

      record.discussion = record.build_discussion
      record.dispatcher = user
    end

    before(:build) { Shipment.skip_callback(:create, :after, :notify_of_new_shipment) }
    after(:build) { Shipment.set_callback(:create, :after, :notify_of_new_shipment) }
  end
end
