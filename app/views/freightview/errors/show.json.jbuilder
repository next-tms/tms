if errors
  json.errors errors do |error|
    json.message error[:message]
    json.propertyName Array(error[:property]).map { |key| key.to_s.camelize(:lower) }.join('.')
  end
end
json.message message
json.name name
json.requestId request.request_id
