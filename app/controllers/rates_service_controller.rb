# frozen_string_literal: true

class RatesServiceController < ApplicationController
  before_action :set_broker_carrier
  before_action :set_shipment
  before_action :set_use_forced_freight_classes

  def fetch
    @rates = Rate.by_shipment_and_broker_carrier(@shipment, @broker_carrier, @use_forced_freight_classes)

    if @rates.blank?
      fetch = RatesService
              .new(
                broker_carrier: @broker_carrier,
                shipment: @shipment,
                use_forced_freight_classes: @use_forced_freight_classes,
                save_new_rates: true
              )

      @rates = fetch.to_rates
    end

    respond_to do |format|
      format.turbo_stream { render }
    end
  end

  private

  def set_broker_carrier
    @broker_carrier = BrokerCarrier.find(params[:broker_carrier_id])
  end

  def set_shipment
    @shipment = Shipment.find(params[:shipment_id])
  end

  def set_use_forced_freight_classes
    @use_forced_freight_classes = params[:use_forced_freight_classes] == 'true'
  end
end
