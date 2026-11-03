module Types
  class BrokerCustomerFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters BrokerCustomer
  end
end
