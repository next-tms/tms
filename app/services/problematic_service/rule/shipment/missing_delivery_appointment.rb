# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingDeliveryAppointment < Rule::Shipment
    ROLES = %i[dispatch].freeze

    def humanized(*)
      'missing delivery appointment'
    end

    def problematic?
      record.picked_up &&
        record.picked_up <= 15.hours.ago &&
        !!resolvable?
    end

    def resolvable?
      !record.picked_up? ||
        record.delivery_appointment_at.present? ||
        record.delivery_appointment_on.present? ||
        record.delivered?
    end
  end
end
