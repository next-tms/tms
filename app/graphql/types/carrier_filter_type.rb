module Types
  class CarrierFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters Carrier
  end
end
