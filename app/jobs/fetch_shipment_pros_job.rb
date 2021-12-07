# frozen_string_literal: true

class FetchShipmentProsJob < ApplicationJob
  def perform
    shipments = Shipment
                .pending_pickup
                .where.not(pickup_confirmation: [nil, ''])
                .where(broker_carrier: BrokerCarrier.api_configured)

    shipments.find_each do |shipment|
      FetchShipmentProJob.perform_later(shipment)
    end
  end
end
