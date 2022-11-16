# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingTotalChargeCents < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'missing charge'
    end

    def problematic?
      record.total_charge_cents.blank? && !resolvable?
    end

    def resolvable?
      (record.total_charge_cents.present? && record.picked_up_at.blank?) || record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
