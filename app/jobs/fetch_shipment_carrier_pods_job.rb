# frozen_string_literal: true

class FetchShipmentCarrierPodsJob < ApplicationJob
  def perform(shipment_ids = nil)
    shipments = if shipment_ids.blank?
                  Shipment
                    .left_joins(:carrier_pod_attachment)
                    .group(:id)
                    .having('COUNT(active_storage_attachments) = 0')
                    .where(broker_carrier: BrokerCarrier.api_configured)
                    .where(delivered_at: 1.month.ago..12.hours.ago)
                    .or(
                      Shipment
                      .where(broker_carrier: BrokerCarrier.api_configured)
                      .where(
                        id: Receivable.unpaid.map { |r| r.shipment_id if r.missing_carrier_pod? }.reject(&:nil?)
                      )
                    )
                    .includes(broker_carrier: :carrier)
                else
                  Shipment.where(id: shipment_ids).includes(broker_carrier: :carrier)
                end

    shipments.find_each do |shipment|
      next unless shipment.broker_carrier&.carrier&.as_interstellar_carrier

      FetchShipmentCarrierPodJob.perform_later(shipment)
    end
  end
end
