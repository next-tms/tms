module Freightview
  class << self
    def decode(value) = value.to_s.parameterize(separator: '_').to_sym
    def decode_keys(hash) = hash.to_hash.deep_transform_keys { |key| key.to_s.underscore.to_sym }
    def encode_keys(hash) = hash.deep_transform_keys { |key| key.to_s.camelize(:lower) }

    def location_accessorials(shipment, stop)
      codes = freight_kit_codes(shipment)

      [*ACCESSORIALS.fetch(stop).select { |_key, code| codes.include?(code) }.keys, ship_type(shipment, stop)].compact
    end

    def packaging_type(packaging) = PACKAGING_TYPES.find { |type| type.to_s == packaging&.freight_kit_type } || :piece

    def ship_type(shipment, stop)
      codes = freight_kit_codes(shipment)

      SHIP_TYPES.find { |ship_type| codes.include?(:"#{ship_type}_#{STOPS.fetch(stop).last}") }
    end

    def shipment_status(shipment) = SHIPMENT_STATUSES.fetch(shipment.status.to_sym, :pending)
    def time(value) = value.presence && Time.zone.parse(value)&.strftime('%H:%M')
    def tracking_status(shipment) = TRACKING_STATUSES.fetch(shipment.status.to_sym, :pending)

    private

    def freight_kit_codes(shipment)
      shipment.broker_accessorials.filter_map { |broker_accessorial| broker_accessorial.accessorial.freight_kit_code&.to_sym }
    end
  end

  ACCESSORIALS = {
    destination: {
      inside: :inside_delivery,
      liftgate: :liftgate_delivery,
      notify: :notify_before_delivery,
      schedule: :appointment_delivery
    },
    origin: { inside: :inside_pickup, liftgate: :liftgate_pickup }
  }.freeze
  PACKAGING_TYPES = %i[
    bag
    bale
    basket
    box
    bundle
    carpet
    case
    coil
    crate
    cylinder
    drum
    jerrican
    keg
    pail
    pallet
    piece
    reel
    roll
    tote
    tube
    unit
  ].freeze
  SHIP_TYPES = %i[limited_access residential].freeze
  SHIPMENT_STATUSES = {
    booked: :awarded,
    booked_quoted: :awarded,
    canceled: :canceled,
    delivered: :delivered,
    delivery_scheduled: :picked_up,
    dispatched: :confirmed,
    in_transit: :picked_up,
    out_for_delivery: :picked_up,
    pending_delivery_appointment: :picked_up,
    pickup_scheduled: :confirmed
  }.freeze
  STOPS = { destination: %i[receiver delivery], origin: %i[shipper pickup] }.freeze
  TRACKING_STATUSES = {
    delivered: :delivered,
    delivery_scheduled: :in_transit,
    dispatched: :enroute_to_pickup,
    in_transit: :in_transit,
    out_for_delivery: :out_for_delivery,
    pending_delivery_appointment: :in_transit
  }.freeze
end
