desc 'Track shipments pending delivery'
task track_pending_pickups_job: :environment do
  TrackShipmentsJob.perform_later(Shipment.active.pending_delivery.pluck(:id))
end

desc 'Track shipments pending departure'
task track_pending_pickups_job: :environment do
  TrackShipmentsJob.perform_later(Shipment.active.pending_departure.pluck(:id))
end

desc 'Track shipments pending pickup'
task track_pending_pickups_job: :environment do
  TrackShipmentsJob.perform_later(Shipment.active.pending_pickup.pluck(:id))
end