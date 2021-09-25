# frozen_string_literal: true

class FetchShipmentCarrierBolJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_carrier_bol
  end
end
