# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::Lost < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'lost'
    end

    def problematic?
      record.lost_on.present? && !resolvable?
    end

    def resolvable?
      record.lost_on.blank? || record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
