# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::NotPickedUp < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'picked missed'
    end

    def problematic?
      return false unless record.pickup_by.present?

      record.picked_up_at.blank? && !resolvable?
    end

    def resolvable?
      return true if record.pickup_by.blank?

      record.picked_up_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
