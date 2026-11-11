class ShipmentAccessorial < ApplicationRecord
  belongs_to :accessorial
  belongs_to :shipment
end
