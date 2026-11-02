json.equipmentInformation do
  json.driverName nil
  json.gpsCoordinates nil
  json.stopsAway nil
  json.trailerNumber nil
end
json.informationCode do
  json.code @pickup_request.status
  json.codeDescription t(@pickup_request.status.parameterize(separator: '_'), scope: 'dsdc.pickup_requests.statuses')
  json.subCode @pickup_request.reschedule_reason
  json.subCodeDescription enum_l(@pickup_request, :reschedule_reason)
end
json.pickupConfirmationId @pickup_request.id.to_s
json.shipmentArray @pickup_request.shipments do |shipment|
  json.destinationCountry shipment.receiver_address.country&.alpha3
  json.destinationPostalCode shipment.receiver_address.zip_code
  json.handlingUnitQuantity shipment.total_pieces
  json.proNumber shipment.load_id.to_s
  json.referenceNumbers(
    {
      BOL: shipment.bol, PO: shipment.customer_reference,
      SO: shipment.shipper_reference
    }.compact_blank.map do |reference_type, reference_value|
      { referenceType: reference_type, referenceValue: reference_value }
    end
  )
  json.weight shipment.total_weight
end
json.status @pickup_request.status
json.stopEta nil
json.stopEtaTimeZone @pickup_request.shipments.first&.pickup_from&.formatted_offset
