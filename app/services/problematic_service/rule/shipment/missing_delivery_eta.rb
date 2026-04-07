module ProblematicService
  class Rule::Shipment::MissingDeliveryEta < Rule::Shipment
    ROLES = %i[dispatch root].freeze

    def humanized(*)
      'missing delivery ETA'
    end

    def problematic?
      record.picked_up? && record.picked_up_at <= 15.hours.ago && !resolvable?
    end

    def resolvable?
      !record.picked_up? || record.delivery_eta_on.present? || record.delivered?
    end
  end
end
