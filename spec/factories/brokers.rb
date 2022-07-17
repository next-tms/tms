# frozen_string_literal: true

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
    name { 'MyString' }
    address { create(:address) }
    phone { 'MyString' }
    customer_service_email { 'test@test.com' }
    first_load_id { 1 }
    default_bol_notes { 'MyText' }
    robot_email { 'MyString' }
    time_zone_name { 'MyString' }
    uuid { '' }
    automatically_authorize_receivables { false }
    automatically_update_shipment_tracking_based_on_carrier_apis { false }
  end
end
