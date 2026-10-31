class Shipment::CreateRatesJob < ApplicationJob
  queue_as :high_priority

  def perform(shipment, shipment_fingerprint, user_type, declared_freight_classes, broker_carrier_ids = [])
    raise ArgumentError, 'declared_freight_classes must be one of true, false' if [true, false].exclude?(declared_freight_classes)

    raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(Shipment)
    raise ArgumentError, 'shipment_fingerprint must be a String' unless shipment_fingerprint.is_a?(String)
    raise ArgumentError, 'user_type must be one of :broker, :customer' if %i[broker customer].exclude?(user_type)

    return if shipment.reload.fingerprint != shipment_fingerprint

    broker_carriers = if broker_carrier_ids.any?
                        BrokerCarrier.where(id: broker_carrier_ids)
                      else
                        shipment.valid_broker_carriers_for_quotation(user_type)
                      end

    # @note Using RANDOM() order so that one slow request doesn't always slow down following requests
    broker_carriers.order(Arel.sql('RANDOM()')).each do |broker_carrier|
      rates = Shipment::RatesService.call(broker_carrier, shipment, declared_freight_classes:, save: true)

      partial = ApplicationController.render(partial: 'rates_service/rates', locals: { shipment:, rates:, user_type: })
      data = { html: partial, declared_freight_classes:, cost: rates.map(&:cost_cents).max }

      ActionCable.server.broadcast("rates_channel_#{shipment.id}", data)
    end

    ActionCable.server.broadcast("rates_channel_#{shipment.id}", { finished: true })
  end
end
