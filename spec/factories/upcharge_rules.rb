# == Schema Information
#
# Table name: upcharge_rules
#
# @!attribute id
#   @return []
# @!attribute max
#   @return [Integer]
# @!attribute min
#   @return [Integer]
# @!attribute upcharge_cents
#   @return [Integer]
# @!attribute upcharge_currency
#   @return [String]
# @!attribute upcharge_percentage
#   @return [Float]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_customer_id
#   @return []
# @!attribute packaging_id
#   @return []
#
# Indexes
#
#  index_upcharge_rules_on_broker_customer_id  (broker_customer_id)
#  index_upcharge_rules_on_packaging_id        (packaging_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (packaging_id => packagings.id)
#
FactoryBot.define do
  factory :upcharge_rule do
    broker_customer_id { 1 }
    packaging { create(:packaging) }
    max { 1 }
    min { 1 }
    upcharge_cents { 1 }
    upcharge_currency { 'MyString' }
    upcharge_percentage { 1.5 }
    updated_at { '2023-04-21 00:10:08' }
  end
end
