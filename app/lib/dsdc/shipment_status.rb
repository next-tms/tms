class DSDC::ShipmentStatus
  IN_TRANSIT_EVENT_CODES = ['arrived_at_terminal', 'departed', 'sailed', 'trailer_closed', 'trailer_unloaded'].freeze

  attr_reader :shipment

  delegate :tracking_events, to: :shipment

  def initialize(shipment) = @shipment = shipment
  def accessorial_codes = EBOL.accessorial_codes(shipment.accessorials).uniq
  def all_short_or_lost? = shipment.lost_on.present? && latest_event_code != 'found'
  def appointment_at = shipment.delivery_appointment_at || shipment.delivery_appointment_on
  def appointment_required? = accessorial_codes.include?('APTD')

  def appointment_status
    return 'Secured' if appointment_at.present?

    'Requested' if appointment_required?
  end

  def cross_border? = shipment.shipper_address.country_alpha2 != shipment.receiver_address.country_alpha2
  def delivery_accessorial_codes = accessorial_codes & EBOL::DELIVERY_ACCESSORIAL_CODES
  def estimated_delivery_at = shipment.quoted_delivery_by || shipment.promised_delivery_by
  def latest_event_code = latest_tracking_event&.event&.active_shipping_code
  def latest_tracking_event = tracking_events.select { |tracking_event| tracking_event.public? && tracking_event.at }.max_by(&:at)

  def milestone_status
    return 'Delivered' if shipment.delivered_at.present?
    return 'Out for Delivery' if shipment.out_for_delivery_at.present?
    return 'In Transit' if shipment.departed_origin_terminal_at.present? || IN_TRANSIT_EVENT_CODES.include?(latest_event_code)

    return if shipment.picked_up_at.blank?

    'Picked-up' # hyphenated, see https://dsdcapis.github.io/less-than-truckload/api-specs/in-transit-visibility/v1.0
  end

  def pro_number = shipment.load_id.to_s
  def time_zone_offset = latest_tracking_event&.time_zone&.formatted_offset
  def transit_days = shipment.applied_rate&.transit_days
  def unique_id = [pro_number, Setting.scac, shipment.created_at.strftime('%Y%m%d')].join
  def updated_eta = appointment_at || shipment.delivery_eta_on || estimated_delivery_at
end
