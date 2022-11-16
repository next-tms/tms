# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingTotalChargeCents < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'missing cost'
    end

    def problematic?
      record.picked_up? && !resolvable?
    end

    def resolvable?
      !record.picked_up? || record.total_charge_cents.present? || record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
