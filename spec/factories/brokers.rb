# == Schema Information
#
# Table name: brokers
#
# @!attribute id
#   @return [Integer]
# @!attribute automatically_authorize_receivables
#   @return [Boolean]
# @!attribute automatically_update_shipment_tracking_based_on_carrier_apis
#   @return [Boolean]
# @!attribute customer_service_email
#   @return [String]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute phone
#   @return [String]
# @!attribute robot_email
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute uuid
#   @return [String]
# @!attribute address_id
#   @return []
# @!attribute first_load_id
#   @return [Integer]
#
# Indexes
#
#  index_brokers_on_address_id  (address_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#
FactoryBot.define do
  factory :broker do
    address { create(:address) }
    automatically_authorize_receivables { false }
    automatically_update_shipment_tracking_based_on_carrier_apis { false }
    customer_service_email { Faker::Internet.email }
    default_bol_notes { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    first_load_id { 1 }
    name { Faker::Company.name }
    phone { Faker::PhoneNumber.phone_number }
    robot_email { Faker::Internet.email }
    time_zone_name { Faker::Address.time_zone }
    uuid { Faker::Internet.uuid }
  end
end
