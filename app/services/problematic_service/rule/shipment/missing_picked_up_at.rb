# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingPickedUpAt < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'not picked up'
    end

    def problematic?
      record.picked_up_at.blank? && !resolvable?
    end

    def resolvable?
      record.picked_up_at.present? ||
      record.booked_at.blank? ||
      record.canceled_at.present? ||
      record.delivered_at.present? ||
      (record.pickup_by.present? && record.pickup_by > Time.current + 8.hours)
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
