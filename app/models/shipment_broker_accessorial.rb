# == Schema Information
#
# Table name: shipment_broker_accessorials
#
# @!attribute id
#   @return []
# @!attribute charge_cents
#   @return [Integer]
# @!attribute charge_currency
#   @return [String]
# @!attribute cost_cents
#   @return [Integer]
# @!attribute cost_currency
#   @return [String]
# @!attribute broker_accessorial_id
#   @return []
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_shipment_broker_accessorials_on_broker_accessorial_id  (broker_accessorial_id)
#  index_shipment_broker_accessorials_on_shipment_id            (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_accessorial_id => broker_accessorials.id)
#  fk_rails_...  (shipment_id => shipments.id)
#
class ShipmentBrokerAccessorial < ApplicationRecord
  belongs_to :broker_accessorial

  monetize :cost_cents, allow_nil: true
  monetize :charge_cents, allow_nil: true

  before_create :calculate_default_charge

  attr_accessor :suggested

  private

  def calculate_default_charge
    cost = self.cost || Money.new(0)
    charge = cost
    if !broker_accessorial.upcharge_percent.blank? && (broker_accessorial.upcharge_percent > 0)
      charge += (cost * (0.01 * broker_accessorial.upcharge_percent))
    end
    charge += broker_accessorial.upcharge if !broker_accessorial.upcharge.blank? && (broker_accessorial.upcharge > 0)
    self.charge = charge
  end
end
