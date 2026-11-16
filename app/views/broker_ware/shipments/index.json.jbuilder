json.key_format! BrokerWare::KEY_FORMAT

json.array! @shipments, partial: 'broker_ware/shipments/load', as: :shipment
