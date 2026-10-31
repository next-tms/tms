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
class UpchargeRule < ApplicationRecord
  audited

  scope :packaging, ->(packaging) { where(packaging:) }

  belongs_to :broker_customer
  belongs_to :packaging

  monetize :upcharge_cents
  validates :min, presence: true
end
