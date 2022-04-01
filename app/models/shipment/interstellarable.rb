# frozen_string_literal: true

module Shipment::Interstellarable
  extend ActiveSupport::Concern

  included do
    def fetch_carrier_bol
      return nil if pro.blank?

      path = begin
        InterstellarApiClient.fetch_bol(broker_carrier:, tracking_number: pro)
      rescue Errno::ENETUNREACH
        nil
      end

      return nil if path.blank?

      unless path.is_a?(String)
        Honeybadger.notify("Shipment#fetch_carrier_bol id=#{id}, path is a #{path.class}")
        return nil
      end

      if File.zero?(path)
        Honeybadger.notify("Shipment#fetch_carrier_bol id=#{id}, carrier_bol was zero-length")
        return nil
      end

      carrier_bol.attach(io: File.open(path), filename: "#{load_id} BOL (Carrier).pdf", content_type: 'application/pdf')

      Contact.where(id: broker_customer.document_preferences.where(kind: 'carrier_bol').pluck(:contact_id)).find_each do |contact|
        ContactMailer.carrier_bol(from_user: nil, to_contact: contact, shipment: self).deliver_later
      end

      problem_type = ProblemType.find_by_code('receivable_missing_carrier_bol')
      problems = Problem.where(problem_type:, shipment: self)

      return true if problems.blank?

      problems.update_all(resolved_at: DateTime.current, resolved_by_id: nil)

      true
    end

    def fetch_carrier_pod
      return nil if pro.blank?

      path = if broker_carrier.carrier.scac == 'OTCL'
               Rails.root.join('public', 'blank.pdf')
             else
               begin
                 InterstellarApiClient.fetch_pod(broker_carrier:, tracking_number: pro)
               rescue Errno::ENETUNREACH
                 nil
               end
             end

      return nil if path.blank?

      if File.zero?(path)
        Honeybadger.notify("Shipment#fetch_carrier_pod id=#{id}, carrier_pod was zero-length")
        return nil
      end

      carrier_pod.attach(io: File.open(path), filename: "#{load_id} POD.pdf", content_type: 'application/pdf')

      Contact.where(id: broker_customer.document_preferences.where(kind: 'carrier_pod').pluck(:contact_id)).find_each do |contact|
        ContactMailer.carrier_pod(from_user: nil, to_contact: contact, shipment: self).deliver_later
      end

      problem_type = ProblemType.find_by_code('receivable_missing_carrier_pod')
      problems = Problem.where(problem_type:, shipment: self)

      return true if problems.blank?

      problems.update_all(resolved_at: DateTime.current, resolved_by_id: nil)

      true
    end

    def fetch_pro
      return nil if pickup_confirmation.blank?

      pro = nil
      pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number: pickup_confirmation,
                                            date: pickup_on)

      if pro.blank?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number: pickup_confirmation,
                                              date: dispatched_at.to_date)
      end

      if pro.blank?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number: pickup_confirmation,
                                              date: pickup_on - 1.day)
      end

      if pro.blank?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number: pickup_confirmation,
                                              date: pickup_on + 1.day)
      end

      if pro.blank?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number: pickup_confirmation,
                                              date: pickup_on + 2.days)
      end

      if pro.blank?
        pro = InterstellarApiClient.fetch_pro(broker_carrier:, pickup_number: pickup_confirmation,
                                              date: dispatched_at.to_date + 1.day)
      end

      return if pro.blank?

      update(pro:, updated_by: nil)
    end

    def interstellar_tracking
      return @interstellar_tracking if @interstellar_tracking

      # Do not check broker_carrier.account, broker_carrier.username, broker_carrier.password as `nil` can be passed on
      return nil if pro.blank? && pickup_confirmation.blank?
      return nil if broker_carrier.blank? || broker_carrier.carrier.scac.blank?

      tracking_number = if pro.blank?
                          broker_carrier.carrier.has_traceable_pickup_confirmation? ? pickup_confirmation : nil
                        else
                          pro
                        end
      return nil if tracking_number.blank?

      @interstellar_tracking = InterstellarApiClient.fetch_tracking(
        broker_carrier:,
        tracking_number:
      )
    end

    def update_tracking_events
      return if interstellar_tracking&.shipment_events.blank?

      interstellar_tracking.shipment_events.each do |shipment_event|
        next if shipment_event.time.blank? || shipment_event.time >= 1.day.from_now || shipment_event.status.blank?

        interstellar_location = if shipment_event.status == :delivered && shipment_event.location.blank?
                                  Interstellar::Location.new(
                                    city: receiver_address.city,
                                    state: receiver_address.region.abbreviation,
                                    country: ActiveUtils::Country.find(receiver_address.country.alpha3_code)
                                  )
                                elsif shipment_event.status == :picked_up && shipment_event.location.blank?
                                  Interstellar::Location.new(
                                    city: shipper_address.city,
                                    state: shipper_address.region.abbreviation,
                                    country: ActiveUtils::Country.find(shipper_address.country.alpha3_code)
                                  )
                                else
                                  shipment_event.location
                                end

        if interstellar_location.blank? || interstellar_location.city.blank? || interstellar_location.state.blank? || interstellar_location.country.blank?
          next
        end

        fingerprint = Digest::SHA2.hexdigest(
          shipment_event.time +
          shipment_event.status.to_s
        )
        tracking_event = tracking_events.where(interstellar_carrier_fingerprint: fingerprint)&.first
        tracking_event = tracking_events.new if tracking_event.blank?

        tracking_event.at_without_time_zone_string = shipment_event.time

        event = Event.find_by_active_shipping_code(shipment_event.status.to_s)
        next if event.blank?

        tracking_event.assign_attributes(
          city: interstellar_location.city,
          country: Country.find_by_alpha2_code(interstellar_location.country_code(:alpha2)),
          event:,
          interstellar_carrier_fingerprint: fingerprint,
          region: Region.find_by_abbreviation(interstellar_location.state)
        )

        next unless tracking_event.valid?

        # This is a cheap hack for API's that always set the time as 12 AM
        # Wait until validation to get TrackingEvent#at

        now = DateTime.current.in_time_zone(tracking_event.time_zone)

        if tracking_event.at == now.beginning_of_day
          tracking_event.at = if tracking_event.event == Event.find_by_name('delivered')
                                now + 1.second # so that it's after out for delivery
                              else
                                now
                              end
        end

        tracking_event.save

        case tracking_event.event.active_shipping_code
        when 'delivered'
          self.delivered_at = tracking_event.at if delivered_at.blank?
        when 'delivery_appointment_scheduled'
          case shipment_event.message
          when DateTime
            self.delivery_appointment_at = shipment_event.message
          when Date
            self.delivery_appointment_on = shipment_event.message
          else
            next
          end
        when 'out_for_delivery'
          self.out_for_delivery_at = tracking_event.at if out_for_delivery_at.blank?
        when 'pending_delivery_appointment'
          self.pending_appointment_since = tracking_event.at if pending_appointment_since.blank?
        when 'picked_up'
          self.picked_up_at = tracking_event.at if picked_up_at.blank?
        end

        if changed?
          self.updated_by = nil # robot
          save
        end

        next unless departed_origin_terminal_at.blank?

        tracking_event = tracking_events.where(
          event: Event.find_by_active_shipping_code('departed')
        ).order(at: :desc).limit(1)&.first

        next if tracking_event.blank?

        # TrackingEvent expects localized format and converts to UTC
        update(
          departed_origin_terminal_at: (tracking_event.at + shipper_address.time_zone.utc_offset.seconds).to_s(:db),
          updated_by: nil
        )
      end

      tracking_events
    end
  end
end
