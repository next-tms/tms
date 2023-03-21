# frozen_string_literal: true

class Types::ShipmentStatusEnum < Types::BaseEnum
  description 'Shipment Statuses'

  # TODO: Update when Shipment#status table column is implemented
  values [
           'pending_pickup',
           'pending_dispatch',
           'pending_quotation',
           'pending_departure',
           'booked',
           'canceled',
           'delivered',
         ]
end
