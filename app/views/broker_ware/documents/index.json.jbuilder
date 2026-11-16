json.key_format! BrokerWare::KEY_FORMAT

if names?
  json.array!(@documents.map { |attachment| BrokerWare.document_name(attachment) })
else
  json.array! @documents do |attachment|
    json.document_list_type BrokerWare.document_list_type(attachment)
    json.id attachment.id.to_s
    json.name BrokerWare.document_name(attachment)
    json.url rails_blob_url(attachment, expires_in: BrokerWare::DocumentsController::URL_EXPIRES_IN)
  end
end
