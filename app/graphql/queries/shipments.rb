module Queries
  class Shipments < Types::BaseObject
    field :shipment_by_load_id,
          Types::ShipmentType,
          description: 'Fetch Shipment By Load ID',
          authorize: { to: :show?, with: ShipmentPolicy },
          null: true do
            argument :load_id, ID, required: true
          end

    field :shipment_by_broker_carrier,
          Types::ShipmentConnectionType,
          connection: true,
          description: 'Fetch Shipment By Broker Carrier',
          null: true do
            argument :broker_carrier_id, ID, required: true
          end

    field :shipment_by_status,
          Types::ShipmentConnectionType,
          connection: true,
          description: 'Fetch Shipment By Status',
          null: true do
            argument :status, Types::ShipmentStatusEnum, required: true
          end


    Types::QueryType.class_eval do
      def shipment_by_load_id(load_id:)
        Shipment.find_by_load_id(load_id)
      end

      def shipment_by_broker_carrier(broker_carrier_id:)
        broker_carrier = BrokerCarrier.find(broker_carrier_id)
        raise GraphQL::ExecutionError.new "Broker Carrier doesn't exists" unless broker_carrier

        broker_carrier.shipments
      end

      def shipment_by_status(status:)
        Shipment.send(status.to_sym)
      end
    end
  end
end
