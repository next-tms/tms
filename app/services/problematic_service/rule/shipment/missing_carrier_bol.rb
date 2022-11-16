# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingCarrierBol < Rule::Shipment
    ROLES = %i[accounts_receivable dispatch root].freeze

    def humanized(*)
      "Missing #{Shipment.human_attribute_name(:carrier_bol).downcase}"
    end

    def problematic?
      !record.carrier_bol.attached? && !resolvable?
    end

    def resolvable?
      record.carrier_bol.attached? ||
        record.broker_customer.blank? ||
        !record.broker_customer.requires_carrier_bol_on_receivables? ||
        record.canceled_at.present? ||
        record.picked_up_at.blank?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
