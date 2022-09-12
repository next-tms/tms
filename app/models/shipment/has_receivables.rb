# frozen_string_literal: true

module Shipment::HasReceivables
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
      broker_customer_ids = BrokerCustomer.where.not(receivables_schedule: :never).ids
      only_after = Date.parse('2021-12-01').to_date.in_time_zone('America/Los_Angeles').beginning_of_day

      shipment_ids = active.where(broker_customer_id: broker_customer_ids).where('picked_up_at > ?', only_after).ids
      shipments_with_receivables_ids = Receivable.where(shipment_id: shipment_ids).pluck(:shipment_id)

      where(id: shipment_ids).where.not(id: shipments_with_receivables_ids)
    end

    def create_receivable
      return unless receivable?

      CreateReceivableJob.perform_later(self)
    end

    def requires_customer_reference_number_on_receivables?
      broker_customer.requires_customer_reference_number_on_receivables
    end

    def receivable?
      self.reload

      return false unless receivables.blank?
      return false if broker_customer.blank? || picked_up_at.blank?
      return false if broker_customer.receivables_schedule == 'never'
      return false if broker_customer.requires_shipment_delivery_before_receivable? && delivered_at.blank?

      if requires_customer_reference_number_on_receivables? && customer_reference.blank?
        create_missing_customer_reference_problem and return false
      end

      true
    end

    def create_missing_customer_reference_problem
      title = "Load #{load_id} missing customer reference no"
      body = "Load #{load_id} is required to have customer reference no before creating a receivable"

      Problem.create(
        assigned_to: self.dispatcher,
        body:,
        problem_type: missing_customer_preference_number_problem_type,
        resolvable: self,
        title:
      )
    end

    def missing_customer_preference_number_problem_type
      ProblemType.find_or_create(
        code: 'missing_customer_reference_number',
        name: 'missing customer reference number',
        resolvable_class_attribute: 'customer_reference',
        resolvable_class_name: 'Shipment',
        resolvable_class_since_attribute_name: 'dispatched_at',
        resolves_when_class_attribute_is: 'blank_false',
      )
    end
  end
end
