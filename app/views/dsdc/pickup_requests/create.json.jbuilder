shipments = @pickup_payload&.shipments || @pickup_request.shipments

json.array! [@pickup_request] do |pickup_request|
  json.carrierName Setting.name
  json.carrierPickupNumber testing? ? nil : pickup_request.id.to_s
  json.pickupMessage [t(testing? ? 'dsdc.pickup_requests.messages.test' : "dsdc.pickup_requests.messages.#{action_name}")]
  json.pickupStatus testing? ? 'Accepted' : pickup_request.status
  json.routing nil
  json.scac Setting.scac
  json.shipperRef(shipments.flat_map { |shipment| [shipment.load_id.to_s, shipment.shipper_reference] }.compact_blank)
  json.trailerNumber nil
end
