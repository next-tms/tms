# frozen_string_literal: true

class UpdateShipmentTrackingEventsService
  delegate(
    *%i[
       pro
       broker_carrier
       pickup_confirmation
       receiver_address
       shipper_address
       id
       tracking_events
     ],
    to: :shipment,
  )

  def initialize(shipment:)
    @shipment = shipment
  end

  # Update Shipment and Tracking Event Details base from FreightKit Shipment Tracking
  # Events API
  def call
    return if transponder_tracking[:shipmentEvents].blank?

    transponder_tracking[:shipmentEvents].each do |shipment_event|
      transponder_location = build_transponder_location(shipment_event)
      type_code = shipment_event[:typeCode]

      next if missing_location_data(transponder_location)
      if shipment_event[:dateTime].blank?
        log_invalid_data_to_honeybadger(
          shipment_event:,
          attr_name: 'date_time',
        ) && next
      end

      at = TimeZoneService.from_transponder_date_time(shipment_event[:dateTime])

      if at.blank?
        log_invalid_data_to_honeybadger(shipment_event:, attr_name: 'location')
        next if shipment_event.dig(:location, :timeZone).blank?

        # Dodgy hack
        at = Time.current.in_time_zone(shipment_event.dig(:location, :timeZone))
      end

      fingerprint = Digest::SHA2.hexdigest([at.to_fs(:db), type_code.to_s].join)
      tracking_event = tracking_events.where(freight_kit_carrier_fingerprint: fingerprint)&.first || tracking_events.new

      # Hack for carriers that return Midnight on everything
      now = Time.current.in_time_zone(at.time_zone)
      at = now if at == now.beginning_of_day

      time_zone_name = at.time_zone.name

      event = Event.find_by(active_shipping_code: type_code.to_s)
      next if event.blank?

      tracking_event.assign_attributes(tracking_event_attributes(
        transponder_location:,
        fingerprint:,
        time_zone_name:,
        event:,
      ))
      # Keep original time since sometimes we "hack" it above
      tracking_event.at = at if tracking_event.at.blank?

      next unless tracking_event.valid?

      begin
        tracking_event.save
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.message.include?('PG::CharacterNotInRepertoire')

        # Some XML API responses using ISO-8859-1 encoding instead of UTF-8
        tracking_event.api_response.force_encoding('ISO-8859-1')
        tracking_event.save
      end

      next unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?

      update_shipment_base_from_tracking_event_code!(tracking_event)
    end

    return unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?

    if transponder_tracking[:estimatedDeliveryDate].present?
      d = TimeZoneService.from_transponder_date_time(transponder_tracking[:estimatedDeliveryDate]).to_date

      shipment.delivery_eta_on = d
    end

    if transponder_tracking[:scheduledDeliveryDate].present?
      d = TimeZoneService.from_transponder_date_time(transponder_tracking[:scheduledDeliveryDate]).to_date

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

  def transponder_tracking
    @transponder_tracking ||= begin
      tracking = TransponderService.new(shipment:).tracking
      return if tracking[:shipmentEvents].blank?

      tracking
    end
  end

  def build_transponder_location(shipment_event)
    type_code = shipment_event[:typeCode]&.to_sym
    location = shipment_event[:location]
    address = if type_code == :delivered
                receiver_address
              elsif type_code == :picked_up
                shipper_address
              end

    return location unless address && location.blank?

    {
      city: address.city,
      province: address.region.abbreviation,
      country: { alpha2: address.country.aplha2_code }
    }
  end

  def missing_location_data(location)
    location.blank? || location[:city].blank? || location[:province].blank? || location[:country].blank?
  end

  def tracking_event_attributes(transponder_location:, fingerprint:, time_zone_name:, event:)
    {
      api_request: transponder_tracking[:request],
      api_response: transponder_tracking[:response],
      city: transponder_location[:city],
      country: Country.find_by(alpha2_code: transponder_location[:country][:alpha2]),
      event:,
      freight_kit_carrier_fingerprint: fingerprint,
      region: Region.find_by(abbreviation: transponder_location[:province]),
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

    # Needs to return true for the "&& next" in line 27 to execute

    Rails.cache.write(cache_key, 'notified', expires_in: 1.day)

    # Notify only once per day to prevent spam notice in Honeybadger every 30 minutes
    Honeybadger.notify(
      "Shipment id=#{id} #freight_kit_tracking returned ShipmentEvent from #{broker_carrier.carrier.name} with " \
      "invalid ##{attr_name}: #{shipment_event.attributes}",
    )
  end
end

# class UpdateShipmentTrackingEventsService
#   delegate(*%i[
#              pro
#              broker_carrier
#              pickup_confirmation
#              receiver_address
#              shipper_address
#              id
#              tracking_events
#            ], to: :shipment)
#
#   def initialize(shipment:)
#     @shipment = shipment
#   end
#
#   # Update Shipment and Tracking Event Details base from FreightKit Shipment Tracking
#   # Events API
#   def call
#     return unless freight_kit_tracking&.shipment_events.present?
#
#     freight_kit_tracking.shipment_events.each do |shipment_event|
#       freight_kit_location = build_freight_kit_location(shipment_event)
#
#       next if missing_location_data(freight_kit_location)
#       if shipment_event.date_time.blank?
#         log_invalid_data_to_honeybadger(
#           shipment_event:,
#           attr_name: 'date_time',
#         ) && next
#       end
#
#       at = TimeZoneService.from_freight_kit_date_time(shipment_event.date_time)
#
#       if at.blank?
#         log_invalid_data_to_honeybadger(shipment_event:, attr_name: 'location')
#         next if shipment_event.location&.time_zone.blank?
#
#         # Dodgy hack
#         at = Time.current.in_time_zone(shipment_event.location.time_zone)
#       end
#
#       fingerprint = Digest::SHA2.hexdigest([at.to_fs(:db), shipment_event.type_code.to_s].join)
#       tracking_event = tracking_events.where(freight_kit_carrier_fingerprint: fingerprint)&.first || tracking_events.new
#
#       # Hack for carriers that return Midnight on everything
#       now = Time.current.in_time_zone(at.time_zone)
#       at = now if at == now.beginning_of_day
#
#       time_zone_name = at.time_zone.name
#
#       event = Event.find_by(active_shipping_code: shipment_event.type_code.to_s)
#       next if event.blank?
#
#       tracking_event.assign_attributes(tracking_event_attributes(
#         freight_kit_location:,
#         fingerprint:,
#         time_zone_name:,
#         event:,
#       ))
#       # Keep original time since sometimes we "hack" it above
#       tracking_event.at = at if tracking_event.at.blank?
#
#       next unless tracking_event.valid?
#
#       begin
#         tracking_event.save
#       rescue ActiveRecord::StatementInvalid => e
#         raise unless e.message.include?('PG::CharacterNotInRepertoire')
#
#         # Some XML API responses using ISO-8859-1 encoding instead of UTF-8
#         tracking_event.api_response.force_encoding('ISO-8859-1')
#         tracking_event.save
#       end
#
#       next unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?
#
#       update_shipment_base_from_tracking_event_code!(tracking_event)
#     end
#
#     return unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?
#
#     if freight_kit_tracking.estimated_delivery_date.present?
#       d = TimeZoneService.from_freight_kit_date_time(freight_kit_tracking.estimated_delivery_date).to_date
#
#       shipment.delivery_eta_on = d
#     end
#
#     if freight_kit_tracking.scheduled_delivery_date.present?
#       d = TimeZoneService.from_freight_kit_date_time(freight_kit_tracking.scheduled_delivery_date)
#
#       if d.beginning_of_day == d
#         shipment.delivery_appointment_on = d.to_date if shipment.delivery_appointment_on.blank?
#       elsif shipment.delivery_appointment_at.blank?
#         shipment.delivery_appointment_at = d
#       end
#     end
#
#     if shipment.changed?
#       shipment.updated_by = nil # robot
#       shipment.save
#     end
#
#     tracking_events
#   end
#
#   private
#
#   attr_reader :shipment
#
#   def freight_kit_tracking
#     @freight_kit_tracking ||= begin
#       return if pro.blank? && pickup_confirmation.blank?
#       return if broker_carrier.blank? || broker_carrier.carrier.scac.blank?
#
#       tracking_number = if pro.blank?
#                           broker_carrier.carrier.has_traceable_pickup_confirmation? ? pickup_confirmation : nil
#                         else
#                           pro
#                         end
#       return if tracking_number.blank?
#
#       tracking = FreightKitAPIClient.fetch_tracking(broker_carrier:, tracking_number:)
#       return if tracking&.shipment_events.blank?
#
#       tracking
#     end
#   end
#
#   def build_freight_kit_location(shipment_event)
#     if shipment_event.type_code == :delivered && shipment_event.location.blank?
#       FreightKit::Location.new(
#         city: receiver_address.city,
#         state: receiver_address.region.abbreviation,
#         country: ActiveUtils::Country.find(receiver_address.country.alpha3_code),
#       )
#     elsif shipment_event.type_code == :picked_up && shipment_event.location.blank?
#       FreightKit::Location.new(
#         city: shipper_address.city,
#         state: shipper_address.region.abbreviation,
#         country: ActiveUtils::Country.find(shipper_address.country.alpha3_code),
#       )
#     else
#       shipment_event.location
#     end
#   end
#
#   def missing_location_data(freight_kit_location)
#     freight_kit_location.blank? || freight_kit_location.city.blank? ||
#       freight_kit_location.province.blank? || freight_kit_location.country.blank?
#   end
#
#   def tracking_event_attributes(freight_kit_location:, fingerprint:, time_zone_name:, event:)
#     {
#       api_request: freight_kit_tracking.request,
#       api_response: freight_kit_tracking.response,
#       city: freight_kit_location.city,
#       country: Country.find_by(alpha2_code: freight_kit_location.country.code(:alpha2).to_s),
#       event:,
#       freight_kit_carrier_fingerprint: fingerprint,
#       region: Region.find_by(abbreviation: freight_kit_location.province),
#       time_zone_name:
#     }
#   end
#
#   def update_shipment_base_from_tracking_event_code!(tracking_event)
#     case tracking_event.event.active_shipping_code
#     when 'delivered'
#       shipment.delivered_at = tracking_event.at if shipment.delivered_at.blank?
#     when 'departed_origin_terminal'
#       shipment.departed_origin_terminal_at = tracking_event.at if shipment.departed_origin_terminal_at.blank?
#     when 'out_for_delivery'
#       shipment.out_for_delivery_at = tracking_event.at if shipment.out_for_delivery_at.blank?
#     when 'pending_delivery_appointment'
#       shipment.pending_appointment_since = tracking_event.at if shipment.pending_appointment_since.blank?
#     when 'picked_up'
#       shipment.picked_up_at = tracking_event.at if shipment.picked_up_at.blank?
#     end
#   end
#
#   def log_invalid_data_to_honeybadger(shipment_event:, attr_name:)
#     cache_key = "#{id}_shipment_event_invalid_#{attr_name}"
#     notified_today = Rails.cache.read(cache_key)
#
#     return true if notified_today
#
#     # Needs to return true for the "&& next" in line 27 to execute
#
#     Rails.cache.write(cache_key, 'notified', expires_in: 1.day)
#
#     # Notify only once per day to prevent spam notice in Honeybadger every 30 minutes
#     Honeybadger.notify(
#       "Shipment id=#{id} #freight_kit_tracking returned ShipmentEvent from #{broker_carrier.carrier.name} with " \
#       "invalid ##{attr_name}: #{shipment_event.attributes}",
#     )
#   end
# end
