# frozen_string_literal: true

class FetchShipmentCarrierPodsJob < ApplicationJob
  def perform(shipment_ids = nil)
    shipments = if shipment_ids.blank?
                  Shipment
                  .left_joins(:carrier_pod_attachment)
                  .group(:id)
                  .having('COUNT(active_storage_attachments) = 0')
                  .where(delivered_at: 1.month.ago..12.hours.ago)
                  .includes(:broker_carrier)
                else
                  Shipment.where(id: shipment_ids).includes(:broker_carrier)
                end

    shipments.find_each do |shipment|
      next unless shipment.broker_carrier&.api_configured?

      FetchShipmentCarrierPodJob.perform_later(shipment)
    end
  end
end
