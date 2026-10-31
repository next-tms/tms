module Queries
  class BrokerCarriers < Types::BaseObject
    description 'Queries for fetching broker carriers'

    field :broker_carrier, Types::BrokerCarrierType, description: 'Fetch Broker Carrier By ID', null: true do
      argument :id, ID, required: true
    end

    field :broker_carrier_by_broker_customer,
          Types::BrokerCarrierConnectionType,
          connection: true,
          description: 'Fetch Broker Carrier By Broker Customer',
          null: true do
            argument :broker_customer_id, ID, required: true
          end

    Types::QueryType.class_eval do
      def broker_carrier(id:)
        BrokerCarrier.find(id)
      end

      def broker_carrier_by_broker_customer(broker_customer_id:)
        BrokerCarrier.where(broker_customer_id:)
      end
    end
  end
end
