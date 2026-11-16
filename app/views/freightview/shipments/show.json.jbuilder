json.partial! 'freightview/shipments/shipment', shipment: @shipment
json.quotes @quotes, partial: 'freightview/shipments/quote', as: :rate if @quotes
