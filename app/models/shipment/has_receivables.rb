module Shipment::HasReceivables
  extend ActiveSupport::Concern

  class_methods do
    def receivable
      broker_customer_ids = BrokerCustomer.where.not(receivables_schedule: :never).ids
      only_after = Date.parse('2021-12-01').to_date.in_time_zone('America/Los_Angeles').beginning_of_day

      shipment_ids = active.where(broker_customer_id: broker_customer_ids).where('picked_up_at > ?', only_after).ids
      shipments_with_receivables_ids = Receivable.where(shipment_id: shipment_ids).pluck(:shipment_id)

      where(id: shipment_ids).where.not(id: shipments_with_receivables_ids)
    end
  end

  included do
    after_save_commit :create_receivable

    has_many :receivables, dependent: :restrict_with_error

    scope :with_carrier_bol, -> { left_joins(:carrier_bol_attachment).group(:id).having('COUNT(active_storage_attachments) != 0') }

    scope :with_carrier_pod, -> { left_joins(:carrier_pod_attachment).group(:id).having('COUNT(active_storage_attachments) != 0') }

    scope :without_carrier_bol, -> { left_joins(:carrier_bol_attachment).group(:id).having('COUNT(active_storage_attachments) = 0') }

    scope :without_carrier_pod, -> { left_joins(:carrier_pod_attachment).group(:id).having('COUNT(active_storage_attachments) = 0') }

    def create_receivable
      return unless receivable?

      CreateReceivableJob.perform_later(self)
    end

    def requires_customer_reference_number_on_receivables?
      broker_customer.requires_customer_reference_number_on_receivables
    end

    def requires_shipper_reference_number_on_receivables?
      broker_customer.requires_shipment_shipper_reference_on_receivables
    end

    def receivable?
      reload

      return false if receivables.any? ||
                      broker_customer.blank? ||
                      picked_up_at.blank? ||
                      broker_customer.receivables_schedule == 'never' ||
                      (broker_customer.requires_shipment_delivery_before_receivable? && delivered_at.blank?) ||
                      problems_preventing_receivable?

      true
    end

    def problems_preventing_receivable?
      suppressions.where(suppressible_type: 'Receivable').any?
    end
  end
end
