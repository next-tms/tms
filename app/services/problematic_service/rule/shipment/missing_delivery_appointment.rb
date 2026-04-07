module ProblematicService
  class Rule::Shipment::MissingDeliveryAppointment < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'missing delivery appointment'
    end

    def problematic?
      record.picked_up? && !resolvable?
    end

    def resolvable?
      !record.picked_up? ||
        record.delivery_appointment_at.present? ||
        record.delivery_appointment_on.present? ||
        record.delivered?
    end
  end
end
