# frozen_string_literal: true

module ProblematicService
  class Rule::Receivable::MissingCarrierPod < Rule::Receivable
    ROLES = %i[accounts_receivable dispatch root].freeze

    def humanized(*)
      'missing carrier POD'
    end

    def problematic?
      !resolvable?
    end

    def resolvable?
      !broker_customer_requires_carrier_pod_on_receivables? || record.shipment.carrier_pod.attached?
    end

    def roles
      @roles ||= Role.where(name: ROLES.map(&:to_s))
    end

    private

    def broker_customer_requires_carrier_pod_on_receivables?
      @broker_customer_requires_carrier_pod_on_receivables ||=
        record.broker_customer.requires_carrier_pod_on_receivables?
    end
  end
end
