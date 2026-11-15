status = DSDC::ShipmentStatus.new(shipment)
latest_tracking_event = status.latest_tracking_event
carrier = shipment.carrier

json.AllShortOrLostShipment status.all_short_or_lost?
json.AppointmentDate status.appointment_at&.iso8601
json.AppointmentRequired status.appointment_required?
json.AppointmentStatus status.appointment_status
json.BillToAccountNumber shipment.broker_customer_id&.to_s
json.BillToAddress do
  json.partial! 'dsdc/shipments/standard_address',
                account_number: shipment.broker_customer_id&.to_s,
                address: shipment.broker_customer&.office_address,
                name: shipment.broker_customer&.customer&.name
end
json.Commodities shipment.items do |item|
  json.classification item.declared_freight_class
  json.description item.desc
  json.hazardous item.hazmat?
  json.nmfc item.nmfc&.split('-')&.first
  json.nmfcSub item.nmfc&.split('-')&.second
  json.packagingType EBOL.handling_unit_type(item.packaging)
  json.pieces item.quantity
  json.weight item.weight
  json.weightUnit 'lbs'
end
json.ConsigneeAddress do
  json.partial! 'dsdc/shipments/standard_address',
                account_number: nil,
                address: shipment.receiver_address,
                name: shipment.receiver_address.name
end
json.CrossBorder status.cross_border?
json.CrossBorderEntryNumber nil
json.CrossBorderStatus nil
json.DelayReasonCode nil
json.DESaccessorial status.delivery_accessorial_codes
json.DESLimitedAccess nil
json.EstimatedDeliveryDate status.estimated_delivery_at&.iso8601
json.EstimatedStandardDay status.transit_days
json.GrossWeight shipment.items.sum(&:weight)
json.HandlingUnits shipment.items.each_with_index.to_a do |(item, index)|
  json.count item.quantity
  json.dimensionsUnit 'In'
  json.height item.h
  json.index index + 1
  json.length item.l
  json.stackable false
  json.type EBOL.handling_unit_type(item.packaging)
  json.weight item.weight
  json.weightUnit 'lbs'
  json.width item.w
end
json.Late shipment.late?
json.OFDStopsAway nil
json.PartnerCarrierName carrier&.name
json.PartnerCarrierSCAC carrier&.scac
json.PayType 'Prepaid'
json.PickupAddress do
  json.partial! 'dsdc/shipments/standard_address',
                account_number: nil,
                address: shipment.shipper_address,
                name: shipment.shipper_address.name
end
json.PODAvailable shipment.carrier_pod.attached?
json.ProNumber status.pro_number
json.Reconsignment false
json.ReferenceNumbers do
  json.AdditionalReferences shipment.customer_pro
  json.bolNumber shipment.bol
  json.MasterBOL nil
  json.poNumber shipment.customer_reference
  json.QuoteID shipment.quote_id
  json.ShipmentID shipment.shipper_reference
  json.trailerNumber nil
end
json.ShipmentDamage false
json.ShipmentLocation do
  json.city latest_tracking_event&.city
  json.country latest_tracking_event&.country&.alpha3
  json.state latest_tracking_event&.region&.abbreviation
end
json.ShipmentMilestoneStatus status.milestone_status
json.ShipmentMilestoneStatusLong t("activerecord.enums.shipment.statuses.#{shipment.status}")
json.ShipmentShortage false
json.ShipmentTerminalInfo nil
json.ShipType 'Third Party'
json.TimeCriticalInfo nil
json.TimeCriticalType nil
json.TimeZoneOfShipment status.time_zone_offset
json.UniqueID status.unique_id
json.UpdatedETA status.updated_eta&.iso8601
json.UpdatedPro nil
