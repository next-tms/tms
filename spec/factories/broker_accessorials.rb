# == Schema Information
#
# Table name: broker_accessorials
#
# @!attribute id
#   @return []
# @!attribute broker_only
#   @return [Boolean]
# @!attribute code
#   @return [String]
# @!attribute cost
#   @return [Float]
# @!attribute fee
#   @return [Boolean]
# @!attribute flat_charge_cents
#   @return [Integer]
# @!attribute flat_charge_currency
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute upcharge
#   @return [Float]
# @!attribute upcharge_cents
#   @return [Integer]
# @!attribute upcharge_currency
#   @return [String]
# @!attribute upcharge_percent
#   @return [Float]
# @!attribute accessorial_id
#   @return []
# @!attribute broker_customer_id
#   @return []
#
# Indexes
#
#  index_broker_accessorials_on_accessorial_id      (accessorial_id)
#  index_broker_accessorials_on_broker_customer_id  (broker_customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (accessorial_id => accessorials.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#
FactoryBot.define do
  factory :broker_accessorial do
    accessorial { create(:accessorial) }
    name { 'MyString' }
    cost { 1.5 }
    upcharge { 1.5 }
    upcharge_percent { 1.5 }
    upcharge_cents { 1 }
    upcharge_currency { 'USD' }
    broker_only { false }
    sequence(:code) { |number| "CODE#{number}" }
    flat_charge_cents { 1 }
    flat_charge_currency { 'MyString' }
    broker_customer { create(:broker_customer) }
    fee { false }
  end
end
