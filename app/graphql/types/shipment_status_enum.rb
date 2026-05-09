class Types::ShipmentStatusEnum < Types::BaseEnum
  description 'Shipment Statuses'

  values Shipment.statuses.keys
end
