# frozen_string_literal: true

module TransponderService
  class FetchTracking
    class << self
      def call(shipment)
        new(shipment).call
      end
    end

    attr_reader :shipment

    delegate :broker_carrier,
             :id,
             :pickup_confirmation,
             :pro,
             :receiver_address,
             :shipper_address,
             :tracking_events,
             to: :shipment

    def initialize(shipment)
      raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(Shipment)

      @shipment = shipment
    end

    # Updates `Shipment`, `Shipment#tracking_events`
    # @return [Boolean]
    def call
      return false if transponder_tracking.blank?

      transponder_tracking[:events].each { |shipment_event| parse_shipment_event(shipment_event) }

      return true unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?

      estimated_delivery = Parser::DateTime.call(transponder_tracking[:estimated_delivery])

      if estimated_delivery.present?
        shipment.delivery_eta_on = estimated_delivery
      end

      scheduled_delivery = Parser::DateTime.call(transponder_tracking[:scheduled_delivery])

      if scheduled_delivery.present?
        shipment.delivery_appointment_on = scheduled_delivery.to_date

        if !scheduled_delivery.is_a?(Date) && scheduled_delivery != scheduled_delivery.beginning_of_day
          shipment.delivery_appointment_at = scheduled_delivery
        end
      end

      return true unless shipment.changed?

      shipment.updated_by = nil
      shipment.save!

      true
    end

    private

    # Notify Honeybadger only once per day to prevent their spam notice every 30 minutes
    # @return [Boolean]
    def log_invalid_data_to_honeybadger(shipment_event:, attr_name:)
      cache_key = "#{id}_shipment_event_invalid_#{attr_name}"
      notified_today = Rails.cache.read(cache_key)

      return true if notified_today

      Rails.cache.write(cache_key, 'notified', expires_in: 1.day)

      message = <<~MESSAGE
        Shipment id=#{id}: Received invalid #{attr_name} from #{broker_carrier.carrier.name}:

        #{shipment_event}
      MESSAGE

      Honeybadger.notify(message)

      true
    end

    def parse_location(location)
      return [] if location.blank?

      city = location[:city]
      region = Region.find_by!(abbreviation: location[:region_abbreviation])
      country = Parser::Country.call(location[:country])

      [city, region, country]
    end

    def parse_shipment_event(shipment_event)
      city, region, country = parse_location(shipment_event[:location])

      if [city, region, country].any?(&:blank?)
        log_invalid_data_to_honeybadger(shipment_event:, attr_name: 'location')

        return
      end

      at = Parser::DateTime.call(shipment_event[:date_time])

      if at.blank?
        log_invalid_data_to_honeybadger(shipment_event:, attr_name: 'date_time')

        return
      end

      code = shipment_event[:code].downcase

      freight_kit_carrier_fingerprint = Digest::SHA2.hexdigest([at.to_fs(:db), code].join)
      tracking_event = tracking_events.find_or_initialize_by(freight_kit_carrier_fingerprint:)

      # Hack for carriers that return Midnight on everything
      now = Time.current.in_time_zone(at.time_zone)
      at = now if at == now.beginning_of_day
      tracking_event.at ||= at # keep original time since it may have already been hacked

      event = Event.find_by_or_initialize_by(active_shipping_code: code)

      if event.new_record?
        event.name = code.humanize.downcase
        event.save!
      end

      tracking_event.assign_attributes(
        api_request: transponder_tracking[:request],
        api_response: transponder_tracking[:response],
        city:,
        country:,
        event:,
        freight_kit_carrier_fingerprint:,
        region:,
        time_zone_name: at.time_zone.name,
      )

      begin
        tracking_event.save!
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.message.include?('PG::CharacterNotInRepertoire')

        # Some XML API responses using ISO-8859-1 encoding instead of UTF-8
        tracking_event.api_response.force_encoding('ISO-8859-1')
        tracking_event.save!
      end

      return unless shipment.broker.automatically_update_shipment_tracking_based_on_carrier_apis?

      update_shipment_base_from_tracking_event_code!(tracking_event)
    end

    def transponder_tracking
      @transponder_tracking ||= TransponderService.query(:fetch_tracking, shipment.broker_carrier, shipment)
    end

    def update_shipment_base_from_tracking_event_code!(tracking_event)
      case tracking_event.event.active_shipping_code
      when 'delivered'
        shipment.delivered_at ||= tracking_event.at
      when 'departed_origin_terminal'
        shipment.departed_origin_terminal_at ||= tracking_event.at
      when 'out_for_delivery'
        shipment.out_for_delivery_at ||= tracking_event.at
      when 'pending_delivery_appointment'
        shipment.pending_appointment_since ||= tracking_event.at
      when 'picked_up'
        shipment.picked_up_at ||= tracking_event.at
      end
    end
  end
end
