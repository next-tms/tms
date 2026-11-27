class ShipmentAccessorial < ApplicationRecord
  attr_accessor :suggested

  before_create :calculate_default_charge

  belongs_to :accessorial

  monetize :cost_cents, allow_nil: true
  monetize :charge_cents, allow_nil: true

  def accessorial_key = accessorial&.key

  def accessorial_key=(key)
    self.accessorial = Integer(key, exception: false)&.then { |id| Accessorial.find(id) } || Accessorial.with_transponder_codes(key).first
  end

  private

  def calculate_default_charge
    cost = self.cost || Money.new(0)
    charge = cost
    if accessorial.upcharge_percent.present? && accessorial.upcharge_percent.positive?
      charge += (cost * (0.01 * accessorial.upcharge_percent))
    end
    charge += accessorial.upcharge if accessorial.upcharge.present? && accessorial.upcharge.positive?
    self.charge = charge
  end
end
