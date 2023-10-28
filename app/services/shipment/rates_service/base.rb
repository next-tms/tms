# frozen_string_literal: true

class Shipment::RatesService
  class Base
    attr_reader :broker_carrier, :declared_freight_classes, :rates, :shipment

    def initialize(broker_carrier, shipment, declared_freight_classes: true, save:)
      unless broker_carrier.is_a?(BrokerCarrier)
        raise ArgumentError, 'broker_carrier must be a BrokerCarrier'
      end

      unless shipment.is_a?(Shipment)
        raise ArgumentError, 'shipment must be a Shipment'
      end

      if [true, false].none?(declared_freight_classes)
        raise ArgumentError, 'declared_freight_classes must be one of true, false'
      end

      if [true, false].none?(save)
        raise ArgumentError, 'save must be one of true, false'
      end

      @broker_carrier = broker_carrier
      @declared_freight_classes = declared_freight_classes
      @rates = []
      @save = save
      @shipment = shipment
    end

    # @raise NotImplementedError
    # @return Array<Rate>
    def call
      raise NotImplementedError
    end

    private

    # @return [Rate]
    def build_rate(source)
      Rate.new(
        accessorials: Accessorial.combined_accessorials(shipment:),
        broker_carrier:,
        broker_customer: shipment.broker_customer,
        shipment_fingerprint: shipment.fingerprint,
        shipment: shipment,
        source:,
        declared_freight_classes:,
      )
    end

    def ignore_value?
      !!shipment.broker_customer&.ignore_value_on_api_quotes?
    end

    # @return [Boolean]
    def save?
      @save
    end
  end
end
