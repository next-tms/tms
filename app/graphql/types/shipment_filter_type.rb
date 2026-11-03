module Types
  class ShipmentFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters Shipment
  end
end
