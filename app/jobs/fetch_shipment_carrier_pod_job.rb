# frozen_string_literal: true

class FetchShipmentCarrierPodJob < ApplicationJob
  queue_as :watir

  def perform(shipment)
    shipment.fetch_carrier_pod
  end
end
