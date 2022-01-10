# frozen_string_literal: true

desc 'Create receivables for eligible shipments'
task create_receivables: :environment do
  CreateReceivablesJob.perform_later
end

desc 'Fetch bill of lading documents for shipments picked up'
task fetch_carrier_bols: :environment do
  FetchShipmentCarrierBolsJob.perform_later
end

desc 'Fetch proof of delivery documents for shipments delivered'
task fetch_carrier_pods: :environment do
  FetchShipmentCarrierPodsJob.perform_later
end

desc 'Fetch pro for shipments picked up'
task fetch_pros: :environment do
  FetchShipmentProsJob.perform_later
end

desc 'Track shipments pending delivery'
task track_pending_delivery_job: :environment do
  TrackShipmentsPendingDeliveryJob.perform_later
end

desc 'Track shipments pending departure'
task track_pending_departure_job: :environment do
  TrackShipmentsPendingDepartureJob.perform_later
end

desc 'Track shipments pending pickup'
task track_pending_pickups_job: :environment do
  TrackShipmentsPendingPickupJob.perform_later
end
