json.array! @documents do |payment_transaction, attachments|
  json.partial! 'dsdc/documents/document', attachments:, payment_transaction:
end
