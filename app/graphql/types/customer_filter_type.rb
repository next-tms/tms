module Types
  class CustomerFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters BrokerCustomer
  end
end
