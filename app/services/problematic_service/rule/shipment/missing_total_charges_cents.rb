# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingTotalChargesCents < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      "Missing #{::Shipment.human_attribute_name(:total_charges).downcase}"
    end

    def problematic?
      record.total_charges_cents.blank? && !resolvable?
    end

    def resolvable?
      record.total_charges_cents.present? ||
        record.booked_at.blank? ||
        record.canceled_at.present? ||
        record.picked_up_at.blank? ||
        record.receivables.any?
    end
  end
end
