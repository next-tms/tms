# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingPickupConfirmation < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'missing pickup confirmation number'
    end

    def problematic?
      record.pickup_confirmation.blank? && !resolvable?
    end

    def resolvable?
      record.pickup_confirmation.present? ||
        record.dispatched_at.blank? ||
        record.picked_up_at.present? ||
        record.delivered_at.present? ||
        record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
