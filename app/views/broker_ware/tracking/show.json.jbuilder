json.key_format! BrokerWare::KEY_FORMAT

json.array! [@shipment] do |shipment|
  json.billed shipment.total_charges&.to_f
  json.carrier_name shipment.carrier&.name
  json.carrier_scac shipment.carrier&.scac

  { consignee: shipment.receiver_address, shipper: shipment.shipper_address }.each do |stop, address|
    json.set! :"#{stop}_address", address&.street
    json.set! :"#{stop}_address2", address&.street2
    json.set! :"#{stop}_city", address&.city
    json.set! :"#{stop}_country", address&.country_alpha2
    json.set! :"#{stop}_name", address&.name
    json.set! :"#{stop}_state", address&.region&.abbreviation
    json.set! :"#{stop}_zip", address&.zip_code
  end

  estimated_delivery_on = (shipment.delivery_eta_on || shipment.quoted_delivery_by || shipment.promised_delivery_by)&.to_date

  json.estimated_delivery_date BrokerWare.timestamp(estimated_delivery_on)
  json.last_update_date shipment.updated_at&.iso8601
  json.load_id shipment.load_id
  json.miles nil
  json.mode shipment.truckload? ? 'Truckload' : 'LTL'
  json.po_reference shipment.customer_reference
  json.pro_number nil
  json.shipper_number shipment.shipper_reference
  json.status BrokerWare.status_name(shipment)
  json.status_code nil
  json.status_description enum_l(shipment, :status)
end
