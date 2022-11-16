# frozen_string_literal: true

module ProblematicService
  class Rule::Receivable::MissingCarrierBol < Rule::Receivable
    ROLES = %i[accounts_receivable dispatch root].freeze

    def humanized(*)
      'missing carrier BOL'
    end

    def problematic?
      !resolvable?
    end

    def resolvable?
      !broker_customer_requires_carrier_bol_on_receivables? || record.shipment.carrier_bol.attached?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end

    private

    def broker_customer_requires_carrier_bol_on_receivables?
      @broker_customer_requires_carrier_bol_on_receivables ||=
        record.broker_customer.requires_carrier_bol_on_receivables?
    end
  end
end
