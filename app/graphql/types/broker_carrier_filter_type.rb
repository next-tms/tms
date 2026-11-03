module Types
  class BrokerCarrierFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters BrokerCarrier
  end
end
