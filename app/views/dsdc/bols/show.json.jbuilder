json.images do
  json.bol @images&.dig(:bol)
  json.shippingLabels @images&.dig(:shipping_labels)
end
json.messageStatus do
  json.code @information.any? ? '200' : '100'
  json.information @information
  json.message t("dsdc.bols.messages.#{testing? ? 'test' : action_name}")
  json.resolution ''
  json.status @information.any? ? 'WARNING' : 'PASS'
end
json.referenceNumbers do
  json.pro testing? ? nil : @shipment.load_id.to_s
  json.shipmentConfirmationNumber testing? ? nil : @shipment.load_id.to_s
end
json.scac Setting.scac
json.termsAndConditions nil
json.transactionDate Time.current.iso8601
json.version EBOL::VERSION
