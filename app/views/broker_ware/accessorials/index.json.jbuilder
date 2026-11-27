json.array! @accessorials do |accessorial|
  json.code BrokerWare.accessorial_code(accessorial)
  json.description accessorial.name
end
