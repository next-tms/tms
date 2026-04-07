class FetchShipmentCarrierPODJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_carrier_pod
  end
end
