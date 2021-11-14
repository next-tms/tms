# frozen_string_literal: true

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
# @!attribute broker_id
#   @return []
#
# Indexes
#
#  index_broker_accessorials_on_accessorial_id      (accessorial_id)
#  index_broker_accessorials_on_broker_customer_id  (broker_customer_id)
#  index_broker_accessorials_on_broker_id           (broker_id)
#
# Foreign Keys
#
#  fk_rails_...  (accessorial_id => accessorials.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (broker_id => brokers.id)
#
class BrokerAccessorial < ApplicationRecord
  scope :blanket, -> { where(customer: nil) }

  belongs_to :broker, optional: true
  belongs_to :broker_customer, optional: true
  belongs_to :accessorial, optional: true

  validates :code, presence: true
  validates :name, presence: true

  monetize :flat_charge_cents, allow_nil: true
  monetize :upcharge_cents, allow_nil: true
end
