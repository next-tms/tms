module Queries
  class BrokerCustomers < Types::BaseObject
    description 'Queries for fetching broker customers'

    field :broker_customer,
          Types::BrokerCustomerType,
          description: 'Fetch Broker Customer By ID',
          null: true do
            argument :id, ID, required: true
          end

    field :broker_customer_by_customer,
          Types::BrokerCustomerConnectionType,
          connection: true,
          description: 'Fetch Broker Customer By Customer',
          null: true do
            argument :customer_id, ID, required: true
          end

    Types::QueryType.class_eval do
      def broker_customer(id:)
        BrokerCustomer.find(id)
      end

      def broker_customer_by_customer(customer_id:)
        BrokerCustomer.where(customer_id:)
      end
    end
  end
end
