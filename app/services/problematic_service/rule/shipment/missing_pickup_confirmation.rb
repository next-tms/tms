# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingPickupConfirmation < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      "Missing #{::Shipment.human_attribute_name(:pickup_confirmation).downcase}"
    end

    def problematic?
      record.pickup_confirmation.blank? && !resolvable?
    end

    def resolvable?
      record.pickup_confirmation.present? ||
        record.booked_at.blank? ||
        record.dispatched_at.blank? ||
        record.picked_up_at.present? ||
        record.delivered_at.present? ||
        record.canceled_at.present?
    end
  end
end
