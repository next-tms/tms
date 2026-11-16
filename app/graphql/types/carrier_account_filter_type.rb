module Types
  class CarrierAccountFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters BrokerCarrier
  end
end
