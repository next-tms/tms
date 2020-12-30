# frozen_string_literal: true

class ShipmentBrokerAccessorial < ApplicationRecord
  belongs_to :broker, required: false
  belongs_to :broker_accessorial

  monetize :cost_cents, allow_nil: true
  monetize :charge_cents, allow_nil: true

  before_create :calculate_default_charge

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
