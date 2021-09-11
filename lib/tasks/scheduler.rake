desc 'Fetch bill of lading documents for shipments picked up'
task fetch_carrier_bols: :environment do
  FetchShipmentCarrierBolsJob.perform_later
end

desc 'Fetch proof of delivery documents for shipments delivered'
task fetch_carrier_pods: :environment do
  FetchShipmentCarrierPodsJob.perform_later
end

desc 'Track shipments pending delivery'
task track_pending_delivery_job: :environment do
  TrackShipmentsJob.perform_later(Shipment.active.pending_delivery.pluck(:id))
end

desc 'Track shipments pending departure'
task track_pending_departure_job: :environment do
  TrackShipmentsJob.perform_later(Shipment.active.pending_departure.pluck(:id))
end

desc 'Track shipments pending pickup'
task track_pending_pickups_job: :environment do
  TrackShipmentsJob.perform_later(Shipment.active.pending_pickup.pluck(:id))
end
