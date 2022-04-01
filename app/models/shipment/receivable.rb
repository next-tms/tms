# frozen_string_literal: true

module Shipment::Receivable
  extend ActiveSupport::Concern

  included do
    after_commit :create_receivable

    has_many :receivables

    scope :with_carrier_bol, lambda {
      left_joins(:carrier_bol_attachment)
        .group(:id)
        .having('COUNT(active_storage_attachments) != 0')
    }

    scope :with_carrier_pod, lambda {
      left_joins(:carrier_pod_attachment)
        .group(:id)
        .having('COUNT(active_storage_attachments) != 0')
    }

    scope :without_carrier_bol, lambda {
      left_joins(:carrier_bol_attachment)
        .group(:id)
        .having('COUNT(active_storage_attachments) = 0')
    }

    scope :without_carrier_pod, lambda {
      left_joins(:carrier_pod_attachment)
        .group(:id)
        .having('COUNT(active_storage_attachments) = 0')
    }

    def self.receivable
      only_after = Date.parse('2021-12-01').to_date.in_time_zone('America/Los_Angeles').beginning_of_day
      shipment_ids = active.where('picked_up_at > ?', only_after).ids
      shipments_with_receivables_ids = Receivable.where(shipment_id: shipment_ids).pluck(:shipment_id)

      where(id: shipment_ids).where.not(id: shipments_with_receivables_ids)
    end

    def create_receivable
      CreateReceivableJob.perform_later(self)
    end

    def receivable?
      return false unless receivables.blank?
      return false if broker_customer.blank? || picked_up_at.blank?

      true
    end
  end
end
