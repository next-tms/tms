FactoryBot.define do
  factory :shipment do
    broker { create(:broker) }
    broker_carrier_id { 1 }
    shipper_name { "MyString" }
    shipper_reference { "MyString" }
    customer_reference { "MyString" }
    pro { "MyString" }
    pickup_confirmation { "MyString" }
    picked_up { false }
    priority { 1 }
    shipper_unavailable_at { "2022-07-04 19:26:38" }
    receiver_available_at { "2022-07-04 19:26:38" }
    receiver_unavailable_at { "2022-07-04 19:26:38" }
    load { }
    receiver_name { "MyString" }
    shipper_contact_name { "MyString" }
    shipper_contact_phone { "MyString" }
    shipper_contact_email { "MyString" }
    receiver_contact_name { "MyString" }
    receiver_contact_phone { "MyString" }
    receiver_contact_email { "MyString" }
    shipper_bol { "MyString" }
    shipper_address { create(:address) }
    receiver_address { create(:address) }
    bol { "MyString" }
    pickup_on { "2022-07-04" }
    lift_gate_delivery { false }
    notify { false }
    lift_gate_pickup { false }
    delivered_at { "2022-07-04 19:26:38" }
    updated_at { "2022-07-04 19:26:38" }
    delivery_eta_on { "2022-07-04" }
    total_charges_cents { 1 }
    total_charges_currency { "MyString" }
    total_cost_cents { 1 }
    total_cost_currency { "MyString" }
    quote_id { "MyString" }
    picked_up_at { "2022-07-04 19:26:38" }
    dispatched_at { "2022-07-04 19:26:38" }
    shipper_available_at { "2022-07-04 19:26:38" }
    out_for_delivery_at { "2022-07-04 19:26:38" }
    load_id { 1 }
    value_cents { 1 }
    value_currency { "MyString" }
    bol_notes { "MyText" }
    carrier_cost_cents { 1 }
    carrier_cost_currency { "MyString" }
    broker_notes { "MyText" }
    customer_notes { "MyText" }
    carrier_charge_cents { 1 }
    carrier_charge_currency { "MyString" }
    canceled_at { "2022-07-04 19:26:38" }
    broker_customer_id { }
    quoted_delivery_by { "2022-07-04 19:26:38" }
    promised_delivery_by { "2022-07-04 19:26:38" }
    truckload { false }
    pending_appointment_since { "2022-07-04" }
    delivery_appointment_at { "2022-07-04 19:26:38" }
    delivery_appointment_on { "2022-07-04" }
    tracking_carrier_id { }
    tracking_carrier_pro { "MyString" }
    tracking_carrier_pickup_confirmation { "MyString" }
    pickup_hours_start_at { "MyString" }
    pickup_hours_end_at { "MyString" }
    delivery_hours_start_at { "MyString" }
    delivery_hours_end_at { "MyString" }
    applied_rate_id { }
    pickup_eta_at { "MyString" }
    pickup_driver_assigned_at { "2022-07-04 19:26:38" }
    departed_origin_terminal_at { "2022-07-04 19:26:38" }
    quote_only { false }
    lost_on { "2022-07-04" }
    booked_at { "2022-07-04 19:26:38" }
    broker_bol_shipment_fingerprint { "MyString" }
    broker_quote_shipment_fingerprint { "MyString" }
    broker_dispatch_sheet_shipment_fingerprint { "MyString" }
    public_notes { "MyText" }
    created_by_id { }
    status { "MyString" }

    before :build do |shipment|
      Shipment.skip_callback(:create, :after, :notify_of_new_shipment)
    end
  end
end
