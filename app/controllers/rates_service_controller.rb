# frozen_string_literal: true

class RatesServiceController < ApplicationController
  before_action :set_broker_carrier
  before_action :set_shipment
  before_action :set_use_forced_freight_classes

  def fetch
    @rates = Rate
             .where(
               broker_carrier: @broker_carrier,
               shipment_fingerprint: @shipment.fingerprint,
               shipment: @shipment,
               with_calculated_freight_classes: !@use_forced_freight_classes
             )

    if @rates.blank?
      fetch = RatesService
              .new(
                broker_carrier: @broker_carrier,
                shipment: @shipment,
                use_forced_freight_classes: @use_forced_freight_classes
              )

      @rates = fetch.to_rates
      @rates.each { |rate| rate.save }
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
    @use_forced_freight_classes = params[:use_forced_freight_classes] == 'true' ? true : false
  end
end
