FactoryBot.define do
  factory :broker do
    name { "MyString" }
    address { create(:address) }
    phone { "MyString" }
    customer_service_email { "test@test.com" }
    first_load_id { 1 }
    default_bol_notes { "MyText" }
    robot_email { "MyString" }
    time_zone_name { "MyString" }
    uuid { "" }
    automatically_authorize_receivables { false }
    automatically_update_shipment_tracking_based_on_carrier_apis { false }
  end
end
