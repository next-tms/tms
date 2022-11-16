# frozen_string_literal: true

module ProblematicService
  class Rule::Receivable::ChargesUnconfirmed < Rule::Receivable
    ROLES = %i[accounts_receivable dispatch root].freeze

    def humanized(*)
      'charges unconfirmed'
    end

    def problematic?
      record.paid_at.blank? &&
        broker_carrier_requires_charges_confirmed_on_receivables? &&
        record.shipment.charges_confirmed?
    end

    def resolvable?
      !problematic?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end

    private

    def broker_carrier_requires_charges_confirmed_on_receivables?
      @broker_carrier_requires_charges_confirmed_on_receivables ||=
        record.broker_customer.broker_carrier_requires_charges_confirmed_on_receivables?
    end
  end
end
