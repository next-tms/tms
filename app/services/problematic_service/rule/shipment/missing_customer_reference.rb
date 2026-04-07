# frozen_string_literal: true

module ProblematicService
  class Rule::Shipment::MissingCustomerReference < Rule::Shipment
    ROLES = %i[accounts_receivable dispatch root].freeze

    def humanized(*)
      "Missing #{::Shipment.human_attribute_name(:customer_reference).downcase}"
    end

    def problematic?
      record.customer_reference.blank? && !resolvable?
    end

    def resolvable?
      record.customer_reference.present? ||
        record.broker_customer.blank? ||
        !record.broker_customer.requires_customer_reference_number_on_receivables? ||
        record.canceled_at.present? ||
        record.picked_up_at.blank? ||
        record.receivables.any?
    end

    def suppressor_instigators
      [ record.broker, record.broker_customer ].compact
    end

    def suppressor_suppressible_types
      [ 'Receivable' ]
    end
  end
end
