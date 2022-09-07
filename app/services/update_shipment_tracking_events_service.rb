# frozen_string_literal: true

class UpdateShipmentTrackingEventsService
  delegate *%i[
    pro
    broker_carrier
    pickup_confirmation
    receiver_address
    shipper_address
    id
    tracking_events
  ], to: :shipment

  def initialize(shipment:)
    @shipment = shipment
  end

  # Update Shipment and Tracking Event Details base from Interstellar Shipment Tracking
  # Events API
  def call
    return unless interstellar_tracking&.shipment_events.present?

    interstellar_tracking.shipment_events.each do |shipment_event|
      interstellar_location = build_interstellar_location(shipment_event)

      next if missing_location_data(interstellar_location)
      log_invalid_data_to_honeybadger(shipment_event:, attr_name: 'date_time') && next if shipment_event.date_time.blank?

      at = TimeZoneService.from_interstellar_date_time(shipment_event.date_time)

      if at.blank?
        log_invalid_data_to_honeybadger(shipment_event:, attr_name: 'location')
        next if shipment_event.location&.time_zone.blank?

        # Dodgy hack
        at = DateTime.current.in_time_zone(shipment_event.location.time_zone)
      end

      fingerprint = Digest::SHA2.hexdigest([at.to_fs(:db), shipment_event.type_code.to_s].join)
      tracking_event = tracking_events.where(interstellar_carrier_fingerprint: fingerprint)&.first || tracking_events.new

      # Hack for carriers that return Midnight on everything
      now = DateTime.current.in_time_zone(at.time_zone)
      at = now if at == now.beginning_of_day

      time_zone_name = at.time_zone.name

      event = Event.find_by_active_shipping_code(shipment_event.type_code.to_s)
      next if event.blank?

      tracking_event.assign_attributes(tracking_event_attributes(interstellar_location:, fingerprint:, time_zone_name:, event:))
      # Keep original time since sometimes we "hack" it above
      tracking_event.at = at if tracking_event.at.blank?

      next unless tracking_event.valid?

      tracking_event.save

      next unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?

      update_shipment_base_from_tracking_event_code!(tracking_event)
    end

    return unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?

    unless interstellar_tracking.estimated_delivery_date.blank?
      d = TimeZoneService.from_interstellar_date_time(interstellar_tracking.estimated_delivery_date).to_date

      shipment.delivery_eta_on = d
    end

    unless interstellar_tracking.scheduled_delivery_date.blank?
      d = TimeZoneService.from_interstellar_date_time(interstellar_tracking.scheduled_delivery_date)

      if d.beginning_of_day == d
        shipment.delivery_appointment_on = d.to_date if shipment.delivery_appointment_on.blank?
      elsif shipment.delivery_appointment_at.blank?
        shipment.delivery_appointment_at = d
      end
    end

    if shipment.changed?
      shipment.updated_by = nil # robot
      shipment.save
    end

    tracking_events
  end

  private

  attr_reader :shipment

  def interstellar_tracking
    @interstellar_tracking ||= begin
      return if pro.blank? && pickup_confirmation.blank?
      return if broker_carrier.blank? || broker_carrier.carrier.scac.blank?

      tracking_number = if pro.blank?
                          broker_carrier.carrier.has_traceable_pickup_confirmation? ? pickup_confirmation : nil
                        else
                          pro
                        end
      return if tracking_number.blank?

      tracking = InterstellarApiClient.fetch_tracking(broker_carrier:, tracking_number:)
      return unless tracking&.shipment_events.present?

      tracking
    end
  end

  def build_interstellar_location(shipment_event)
    if shipment_event.type_code == :delivered && shipment_event.location.blank?
      Interstellar::Location.new(
        city: receiver_address.city,
        state: receiver_address.region.abbreviation,
        country: ActiveUtils::Country.find(receiver_address.country.alpha3_code)
      )
    elsif shipment_event.type_code == :picked_up && shipment_event.location.blank?
      Interstellar::Location.new(
        city: shipper_address.city,
        state: shipper_address.region.abbreviation,
        country: ActiveUtils::Country.find(shipper_address.country.alpha3_code)
      )
    else
      shipment_event.location
    end
  end

  def missing_location_data(interstellar_location)
    interstellar_location.blank? || interstellar_location.city.blank? ||
    interstellar_location.province.blank? || interstellar_location.country.blank?
  end

  def tracking_event_attributes(interstellar_location:, fingerprint:, time_zone_name:, event:)
    {
      api_request: interstellar_tracking.request,
      api_response: interstellar_tracking.response,
      city: interstellar_location.city,
      country: Country.find_by_alpha2_code(interstellar_location.country.code(:alpha2).to_s),
      event:,
      interstellar_carrier_fingerprint: fingerprint,
      region: Region.find_by_abbreviation(interstellar_location.province),
      time_zone_name:
    }
  end

  def update_shipment_base_from_tracking_event_code!(tracking_event)
    case tracking_event.event.active_shipping_code
    when 'delivered'
      shipment.delivered_at = tracking_event.at if shipment.delivered_at.blank?
    when 'departed_origin_terminal'
      shipment.departed_origin_terminal_at = tracking_event.at if shipment.departed_origin_terminal_at.blank?
    when 'out_for_delivery'
      shipment.out_for_delivery_at = tracking_event.at if shipment.out_for_delivery_at.blank?
    when 'pending_delivery_appointment'
      shipment.pending_appointment_since = tracking_event.at if shipment.pending_appointment_since.blank?
    when 'picked_up'
      shipment.picked_up_at = tracking_event.at if shipment.picked_up_at.blank?
    end
  end

  def log_invalid_data_to_honeybadger(shipment_event:, attr_name:)
    cache_key = "#{id}_shipment_event_invalid_#{attr_name}"
    notified_today = Rails.cache.read(cache_key)

    return true if notified_today

    Rails.cache.write(cache_key, "notified", expires_in: 1.day)

    # Notify only once per day to prevent spam notice in Honeybadger every 30 minutes
    Honeybadger.notify(
      "Shipment id=#{id} #interstellar_tracking returned ShipmentEvent from #{broker_carrier.carrier.name} with "\
      "invalid ##{attr_name}: #{shipment_event.attributes}"
    )
  end
end
