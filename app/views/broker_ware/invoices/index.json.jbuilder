json.key_format! BrokerWare::KEY_FORMAT

json.array! @receivables do |receivable|
  shipment = receivable.shipment

  json.accessorials receivable.receivable_items do |receivable_item|
    json.billed receivable_item.charge.to_f
    json.description receivable_item.description
  end

  json.commodities shipment.items do |item|
    json.set! :class, item.display_freight_class&.to_s
    json.description item.desc
    json.pieces item.quantity
    json.weight item.weight
  end

  unless custom_fields?
    parties = {
      bill_to: [shipment.broker_customer&.office_address, shipment.broker_customer&.customer&.name],
      consignee: [shipment.receiver_address, shipment.receiver_address&.name],
      remit_to: [Setting.mailing_address, Setting.name],
      shipping: [shipment.shipper_address, shipment.shipper_address&.name]
    }

    parties.each do |party, (address, company)|
      json.set! :"#{party}_address", address&.street
      json.set! :"#{party}_address2", address&.street2
      json.set! :"#{party}_city", address&.city
      json.set! :"#{party}_company", company
      json.set! :"#{party}_state", address&.region&.abbreviation
      json.set! :"#{party}_zip", address&.zip_code
    end

    json.remit_to_fax nil
    json.remit_to_phone Setting.phone
  end

  json.custom_fields(custom_fields? ? [] : nil)
  json.delivery_date shipment.delivered_at&.strftime(BrokerWare::DATE_FORMAT)
  json.due_date receivable.due_by&.in_time_zone(Setting.time_zone)&.strftime(BrokerWare::DATE_FORMAT)
  json.invoice_date receivable.created_at.in_time_zone(Setting.time_zone).strftime(BrokerWare::DATE_FORMAT)
  json.invoice_number shipment.load_id.to_s
  json.load_id shipment.load_id
  json.pickup_date (shipment.picked_up_at&.to_date || shipment.pickup_on)&.strftime(BrokerWare::DATE_FORMAT)
  json.po_reference shipment.customer_reference
  json.pro_number nil
  json.shipper_number shipment.shipper_reference
  json.term nil
  json.total_billed receivable.total.to_f
  json.total_charges receivable.total.to_f
  json.total_paid (receivable.total - receivable.balance).to_f
  json.total_weight(shipment.items.sum { |item| item.weight.to_i })
end
