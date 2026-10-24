module ProblematicService
  class Rule::Shipment::MissingDeliveryAt < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'not delivered'
    end

    def problematic?
      record.delivered_at.blank? && !resolvable?
    end

    def resolvable?
      today = Time.current.in_time_zone(record.receiver_address&.time_zone.presence || Setting.time_zone).to_date

      record.delivered_at.present? ||
        record.booked_at.blank? ||
        record.picked_up_at.blank? ||
        (record.delivery_eta_on.present? && record.delivery_eta_on > today) ||
        (record.promised_delivery_by.present? && record.promised_delivery_by > 12.hours.from_now) ||
        record.picked_up_at < 24.hours.ago
    end
  end
end
