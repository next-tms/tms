# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingTotalCostCents < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      "Missing #{Shipment.human_attribute_name(:total_cost).downcase}"
    end

    def problematic?
      record.total_cost_cents.blank? && !resolvable?
    end

    def resolvable?
      record.total_cost_cents.present? || record.picked_up_at.blank? || record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
