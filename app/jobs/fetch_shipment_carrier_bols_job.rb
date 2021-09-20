# frozen_string_literal: true

class FetchShipmentCarrierBolsJob < ApplicationJob
  def perform(shipment_ids = nil)
    shipments = if shipment_ids.blank?
                  Shipment.left_joins(
                    :carrier_bol_attachment
                  ).group(:id).having('COUNT(active_storage_attachments) = 0').where(
                    'picked_up_at > ?', 1.week.ago
                  ).includes(:broker_carrier)
                else
                  Shipment.where(id: shipment_ids).includes(:broker_carrier)
                end

    shipments.find_each do |shipment|
      next if !shipment.broker_carrier&.api_configured?
      FetchShipmentCarrierBolJob.perform_later(shipment)
    end
  end
end
