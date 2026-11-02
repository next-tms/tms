json.uniqueID payment_transaction.dsdc_unique_id
json.shipmentID payment_transaction.dsdc_invoice['shipmentID']
json.DOT payment_transaction.dsdc_invoice['DOT']
json.MC payment_transaction.dsdc_invoice['MC']
json.invoiceNumber payment_transaction.invoice
json.invoiceDate payment_transaction.dsdc_invoice.dig('invoiceHeader', 'invoiceDate')

documents = attachments.group_by { |attachment| attachment.blob.metadata['document_type'] }

json.documents documents do |document_type, typed_attachments|
  json.documentType document_type

  json.files typed_attachments do |attachment|
    json.id attachment.id.to_s
    json.content Base64.strict_encode64(attachment.download)
  end
end
