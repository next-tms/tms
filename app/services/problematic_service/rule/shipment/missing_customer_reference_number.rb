# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingCustomerReferenceNumber < Rule::Shipment
    ROLES = %i[accounts_receivable dispatch].freeze

    def humanized(*)
      'missing PO'
    end

    def problematic?
      return false unless record.broker_customer&.requires_customer_reference_number_on_receivables?

      record.customer_reference.blank? && !resolvable?
    end

    def resolvable?
      return true unless record.broker_customer&.requires_customer_reference_number_on_receivables?

      record.customer_reference.present? || record.canceled_at.present?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end
  end
end
