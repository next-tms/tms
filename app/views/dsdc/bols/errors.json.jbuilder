json.array! errors do |error|
  json.code error[:code]
  json.message error[:message]
end
