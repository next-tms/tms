module Types
  class DocumentKindEnum < Types::BaseEnum
    description 'Document Kinds'

    value 'BOL', value: 'broker_bol'
    value 'CARRIER_BOL', value: 'carrier_label'
    value 'CARRIER_QUOTE', value: 'broker_carrier_quote'
    value 'DISPATCH_SHEET', value: 'broker_dispatch_sheet'
    value 'INVOICE', value: 'invoice'
    value 'LABEL', value: 'broker_label'
    value 'POD', value: 'carrier_pod'
    value 'QUOTE', value: 'broker_quote'
    value 'SCANNED_BOL', value: 'carrier_bol'
  end
end
