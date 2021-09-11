class FetchShipmentCarrierPodsJob < ApplicationJob
  def perform(shipments = nil)
    if shipments.blank?
      shipments = Shipment.left_joins(
        :carrier_pod_attachment
      ).group(:id).having('COUNT(active_storage_attachments) = 0').where(
        'delivered_at > ?', 1.week.ago
      )
    end

    shipments.find_each do |shipment|
      next unless shipment.broker_carrier.api_configured?
      begin
        shipment.fetch_carrier_pod
      rescue StandardError => e
        Rails.env.production? ? Rollbar.critical(e, shipment_id: shipment.id) : warn("Shipment id=#{shipment.id} #{e}")
        next
      end
    end
  end
end
