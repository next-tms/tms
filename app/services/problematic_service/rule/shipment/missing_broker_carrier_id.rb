# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingBrokerCarrierId < Rule::Shipment
    ROLES = %i[dispatch].freeze

    def humanized(*)
      'carrier unassigned'
    end

    def problematic?
      record.broker_carrier_id.blank? && !resolvable?
    end

    def resolvable?
      record.broker_carrier_id.present? || record.booked_at.blank? || record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
