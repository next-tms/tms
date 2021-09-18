# frozen_string_literal: true

class FetchShipmentCarrierPodJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_carrier_pod
  end
end
