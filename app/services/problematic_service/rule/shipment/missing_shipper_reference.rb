# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingShipperReference < Rule::Shipment
    ROLES = %i[accounts_receivable dispatch].freeze

    def humanized(*)
      "Missing #{Shipment.human_attribute_name(:shipper_reference).downcase}"
    end

    def problematic?
      record.shipper_reference.blank? && !resolvable?
    end

    def resolvable?
      record.shipper_reference.present? ||
      record.broker_customer.blank? ||
      !record.broker_customer.requires_shipment_shipper_reference_on_receivables? ||
      record.canceled_at.present? ||
      record.picked_up_at.blank? ||
      record.receivables.any?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end

    def suppressor_instigators
      [record.broker, record.broker_customer].compact
    end

    def suppressor_suppressible_types
      ['Receivable']
    end
  end
end
