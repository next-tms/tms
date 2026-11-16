estimated_delivery_on = (shipment.delivery_appointment_at || shipment.quoted_delivery_by || shipment.promised_delivery_by)&.to_date

json.bill_of_landing_note shipment.bol_notes
json.bol_num shipment.bol

json.carriers Array(shipment.broker_carrier&.carrier) do |carrier|
  json.merge! 'carrierMCNumber' => carrier.mc_number&.to_s
  json.carrier_name carrier.name
  json.carrier_scac carrier.scac
  json.provider_scac carrier.scac
end

json.closingtime BrokerWare.timestamp(shipment.pickup_on, shipment.pickup_hours_end_at)
json.createdate shipment.created_at&.iso8601
json.dockdate shipment.delivery_appointment_at&.iso8601
json.estimated_delivery BrokerWare.timestamp(estimated_delivery_on)
json.estimated_delivery_close_time BrokerWare.timestamp(estimated_delivery_on, shipment.delivery_hours_end_at)
json.estimated_delivery_open_time BrokerWare.timestamp(estimated_delivery_on, shipment.delivery_hours_start_at)

json.items shipment.items do |item|
  json.set! :class, item.display_freight_class&.to_s
  json.height item.h
  json.is_hazardous item.hazmat || false
  json.length item.l
  json.nmfc item.nmfc
  json.packaging item.packaging&.freight_kit_type.to_s.pluralize.capitalize.presence
  json.pieces item.quantity
  json.product_description item.desc
  json.units_dimension 'Inches'
  json.units_weight 'lbs'
  json.weight item.weight
  json.width item.w
end

json.load_id shipment.load_id
json.pickup_close_time BrokerWare.timestamp(shipment.pickup_on, shipment.pickup_hours_end_at)
json.pickup_date BrokerWare.timestamp(shipment.pickup_on)
json.pickup_open_time BrokerWare.timestamp(shipment.pickup_on, shipment.pickup_hours_start_at)
json.po_reference shipment.customer_reference
json.readytime BrokerWare.timestamp(shipment.pickup_on, shipment.pickup_hours_start_at)
json.shipment_mode shipment.truckload? ? 'Truckload' : 'LTL'
json.shipment_status BrokerWare.status_name(shipment)
json.shipper_num shipment.shipper_reference

json.stops [[shipment.shipper_address, 'Pickup'], [shipment.receiver_address, 'Drop']].select(&:first) do |(address, stop_type)|
  json.address1 address.street
  json.address2 address.street2
  json.city address.city
  json.country address.country_alpha2
  json.full_address address.proper(', ')
  json.name address.name
  json.state address.region&.abbreviation
  json.stop_type stop_type
  json.zip address.zip_code
end

json.value shipment.value&.to_f
