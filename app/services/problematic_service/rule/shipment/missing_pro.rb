# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingPro < Rule::Shipment
    ROLES = %i[dispatch].freeze

    def humanized(*)
      'missing tracking number'
    end

    def problematic?
      record.broker_carrier.present? && record.pro.blank? && !resolvable?
    end

    def resolvable?
      record.picked_up_at.blank? || record.delivered_at.present? || record.broker_carrier.blank? || record.pro.present? || record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
