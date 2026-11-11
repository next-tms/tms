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
    if broker_accessorial.upcharge_percent.present? && broker_accessorial.upcharge_percent.positive?
      charge += (cost * (0.01 * broker_accessorial.upcharge_percent))
    end
    charge += broker_accessorial.upcharge if broker_accessorial.upcharge.present? && broker_accessorial.upcharge.positive?
    self.charge = charge
  end
end
