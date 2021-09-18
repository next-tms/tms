# frozen_string_literal: true

class FetchShipmentCarrierBolJob < ApplicationJob
  queue_as :watir

  def perform(shipment)
    shipment.fetch_carrier_bol
  end
end
