# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingCarrierTrackingPro < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      "missing #{record.tracking_carrier&.name} tracking number".squish
    end

    def problematic?
      record.tracking_carrier.present? && record.tracking_carrier_pro.blank? && !resolvable?
    end

    def resolvable?
      record.tracking_carrier.blank? ||
        record.tracking_carrier_pro.present? ||
        record.booked_at.blank? ||
        record.canceled_at.present? ||
        record.delivered_at.present?
    end
  end
end
