# frozen_string_literal: true

class PopulateRatesJob < ApplicationJob
  def perform(shipment_id, user_id, use_forced_freight_class, broker_carrier_ids=[])
    sleep(5)

    shipment = Shipment.find shipment_id
    user = User.find user_id
    if broker_carrier_ids.present?
      broker_carriers = BrokerCarrier.where(id: broker_carrier_ids)
    else
      broker_carriers = shipment.valid_broker_carriers_for_quotation(user_type: :broker)
    end

    broker_carriers.each do |broker_carrier|
      rates = Rate.by_shipment_and_broker_carrier(shipment, broker_carrier, use_forced_freight_class)

      if rates.blank?
        fetch = RatesService
                .new(
                  broker_carrier: broker_carrier,
                  shipment: shipment,
                  use_forced_freight_classes: use_forced_freight_class,
                  save_new_rates: true
                )
  
        begin
          rates = fetch.to_rates
        rescue StandardError
          next
        end
      end

      partial = ApplicationController.render(
        partial: "rates_service/rates",
        locals: { shipment: shipment, rates: rates, user: user }
      )

      data = {
        html: partial,
        use_forced_freight_class: use_forced_freight_class,
        cost: rates.map(&:cost_cents).max
      }

      ActionCable.server.broadcast("rates_channel_#{shipment_id}", data)
    end

    ActionCable.server.broadcast("rates_channel_#{shipment_id}", { finished: true })
  end
end
