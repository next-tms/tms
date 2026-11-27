# Provides access to broker's Stripe API
class Shipment::DuplicateService
  attr_reader :shipment

  NULLABLE_ATTRS = %i[
    canceled_at
    delivered_at
    delivery_appointment_at
    delivery_appointment_on
    delivery_eta_on
    departed_origin_terminal_at
    dispatched_at
    lost_on
    out_for_delivery_at
    pending_appointment_since
    picked_up_at
    pickup_confirmation
    pickup_driver_assigned_at
    pickup_eta_at
    pickup_on
    pickup_request_id
    pro
    quote_id
    quote_only
    quoted_delivery_by
    tracking_carrier_pickup_confirmation
  ].freeze

  def initialize(shipment:)
    @shipment = shipment
  end

  def call
    new_shipment = shipment.dup
    new_shipment.receiver_address = shipment.receiver_address.dup
    new_shipment.shipper_address = shipment.shipper_address.dup
    new_shipment.shipment_accessorials << shipment.shipment_accessorials.collect(&:dup)
    new_shipment.items << shipment.items.collect(&:dup)
    new_shipment.load_id = nil

    # You want a duplicated shipment to have a shipment status of 'New'
    attrs = NULLABLE_ATTRS.map { |attr_name| { attr_name => nil } }
    new_shipment.assign_attributes(attrs.reduce({}, :merge))

    new_shipment.save!

    new_shipment
  end
end
