json.key_format! BrokerWare::KEY_FORMAT

json.array! @rates do |rate|
  if breakdown?
    json.accessorials []
    json.commodities []
    json.rate_quote_id rate.uid
  end

  json.billed rate.charge.to_f
  json.bill_to_code nil
  json.name rate.broker_carrier.carrier.name
  json.scac rate.broker_carrier.carrier.scac
  json.service_description rate.pretty_service_type.presence || 'N/A'
  json.service_type rate.freight_kit_service_type.to_s.include?('guaranteed') ? 'Guaranteed' : 'Standard'
  json.transit_time rate.transit_days.to_s
end
