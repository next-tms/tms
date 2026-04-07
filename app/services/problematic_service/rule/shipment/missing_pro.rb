module ProblematicService
  class Rule::Shipment::MissingPro < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      return "Missing #{::Shipment.human_attribute_name(:pro).downcase}" if record.broker_carrier.blank?

      "Missing #{record.broker_carrier&.carrier&.name} #{::Shipment.human_attribute_name(:pro).downcase}".squish
    end

    def problematic?
      record.pro.blank? && !resolvable?
    end

    def resolvable?
      record.pro.present? ||
        record.booked_at.blank? ||
        record.broker_carrier.blank? ||
        record.canceled_at.present? ||
        record.delivered_at.present? ||
        record.picked_up_at.blank?
    end
  end
end
