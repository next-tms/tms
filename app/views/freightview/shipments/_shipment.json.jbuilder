json.bol do
  json.bolNumber shipment.bol
  json.status shipment.booked_at.present? ? 'ok' : 'not-requested'
end
json.bookedDate shipment.booked_at&.iso8601
json.createdDate shipment.created_at&.iso8601
json.direction 'outbound'
json.items shipment.items do |item|
  nmfc_number, nmfc_sub_number = item.nmfc&.split('-')

  json.description item.desc
  json.dimensionsUOM 'in'
  json.freightClass item.declared_freight_class
  json.height item.h
  json.isHazardous item.hazmat?
  json.itemId item.id.to_s
  json.length item.l
  json.nmfcNumber nmfc_number&.to_i
  json.nmfcSubNumber nmfc_sub_number&.to_i
  json.quantity item.quantity
  json.type Freightview.packaging_type(item.packaging)
  json.weight item.weight
  json.weightUOM 'lbs'
  json.width item.w
end
json.locations %i[origin destination].each_with_index.to_a do |(stop, sequence)|
  json.partial! 'freightview/shipments/location', sequence:, shipment:, stop:
end
json.pickupDate shipment.pickup_on&.iso8601
json.refNums [shipment.customer_reference, shipment.shipper_reference].compact_blank do |value|
  json.type 'other'
  json.value value
end
if shipment.applied_rate
  json.selectedQuote { json.partial! 'freightview/shipments/quote', rate: shipment.applied_rate }
else
  json.selectedQuote nil
end
json.shipmentId shipment.load_id.to_s
json.status Freightview.shipment_status(shipment).to_s.dasherize
json.tracking do
  json.deliveryDateActual shipment.delivered_at&.iso8601
  json.deliveryDateEstimate (shipment.delivery_eta_on || shipment.quoted_delivery_by)&.to_date&.iso8601
  json.pickupDateActual shipment.picked_up_at&.iso8601
  json.status Freightview.tracking_status(shipment).to_s.dasherize
  json.trackingNumber shipment.load_id.to_s
end
