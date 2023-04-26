# Provides access to broker's Stripe API
class Shipment::DuplicateService
  attr_reader :shipment

  NULLABLE_ATTRS = %i[
    quote_only
    picked_up
    pickup_on
    dispatched_at
    pickup_confirmation
    tracking_carrier_pickup_confirmation
    pickup_driver_assigned_at
    pickup_eta_at
    picked_up_at
    departed_origin_terminal_at
    delivery_eta_on
    out_for_delivery_at
    lost_on
    pending_appointment_since
    delivery_appointment_on
    delivery_appointment_at
    delivered_at
    canceled_at
    dispatched_at
    quoted_delivery_by
    quote_id
    pro
  ].freeze

  def initialize(shipment:)
    @shipment = shipment
  end

  def call
    new_shipment = shipment.dup
    new_shipment.receiver_address = shipment.receiver_address.dup
    new_shipment.shipper_address = shipment.shipper_address.dup
    new_shipment.shipment_broker_accessorials << shipment.shipment_broker_accessorials.collect(&:dup)
    new_shipment.items << shipment.items.collect(&:dup)
    new_shipment.load_id = shipment.broker.last_load_id + 1

    # You want a duplicated shipment to have a shipment status of 'New'
    attrs = NULLABLE_ATTRS.map { |attr_name| { attr_name => nil } }
    new_shipment.assign_attributes(attrs.reduce({}, :merge))

    new_shipment.save!

    new_shipment
  end
end
