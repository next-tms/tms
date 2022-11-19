# frozen_string_literal: true

class FetchShipmentCarrierBOLJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_carrier_bol
  end
end
