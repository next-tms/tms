module ProblematicService
  class Rule::Shipment::MissingChargesConfirmed < Rule::Shipment
    ROLES = %i[accounts_receivable dispatch root].freeze

    def humanized(*)
      "missing #{::Shipment.human_attribute_name(:charges_confirmed).downcase}"
    end

    def problematic?
      !resolvable?
    end

    def resolvable?
      record.broker_customer.blank? ||
        !record.broker_customer.requires_charges_confirmed_on_receivables? ||
        record.canceled_at.present? ||
        record.charges_confirmed? ||
        record.picked_up_at.blank? ||
        record.receivables.any?
    end
  end
end
