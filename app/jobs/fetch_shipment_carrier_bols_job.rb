# frozen_string_literal: true

class FetchShipmentCarrierBolsJob < ApplicationJob
  def perform(shipment_ids = nil)
    shipments = if shipment_ids.blank?
                  Shipment
                    .left_joins(:carrier_bol_attachment)
                    .group(:id)
                    .having('COUNT(active_storage_attachments) = 0')
                    .where(broker_carrier: BrokerCarrier.api_configured)
                    .where(picked_up_at: 1.month.ago..12.hours.ago)
                    .or(
                      Shipment
                      .where(broker_carrier: BrokerCarrier.api_configured)
                      .where(
                        id: Receivable.unpaid.map { |r| r.shipment_id if r.missing_carrier_bol? }.reject(&:nil?)
                      )
                    )
                    .includes(:broker_carrier)
                else
                  Shipment.where(id: shipment_ids).includes(broker_carrier: :carrier)
                end

    shipments.find_each do |shipment|
      next unless shipment.broker_carrier&.api_configured? && shipment.broker_carrier.carrier.as_interstellar_carrier

      FetchShipmentCarrierBolJob.perform_later(shipment)
    end
  end
end
