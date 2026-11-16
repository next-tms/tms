json.array! @broker_accessorials do |broker_accessorial|
  json.code BrokerWare.accessorial_code(broker_accessorial.accessorial)
  json.description broker_accessorial.name
end
