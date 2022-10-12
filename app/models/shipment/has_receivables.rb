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

    def requires_shipper_reference_number_on_receivables?
      broker_customer.requires_shipment_shipper_reference_on_receivables
    end

    def receivable?
      self.reload

      return false unless receivables.blank?
      return false if broker_customer.blank? || picked_up_at.blank?
      return false if broker_customer.receivables_schedule == 'never'
      return false if broker_customer.requires_shipment_delivery_before_receivable? && delivered_at.blank?

      if requires_customer_reference_number_on_receivables? && customer_reference.blank?
        create_missing_reference_problem(kind: 'customer_reference') and return false
      end

      if requires_shipper_reference_number_on_receivables? && shipper_reference.blank?
        create_missing_reference_problem(kind: 'shipper_reference') and return false
      end

      true
    end

    def create_missing_reference_problem(kind:)
      title = "Load #{load_id} missing #{kind.humanize} no"
      body = "Load #{load_id} is required to have #{kind.humanize} no before creating a receivable"

      Problem.create(
        assigned_to: self.dispatcher,
        body:,
        problem_type: missing_reference_number_problem_type(kind: kind),
        resolvable: self,
        title:
      )
    end

    def missing_reference_number_problem_type(kind:)
      ProblemType.find_or_create_by(
        role: Role.find_by(name: 'dispatch'),
        code: "missing_#{kind}_number",
        name: "missing #{kind.humanize.downcase} number",
        resolvable_class_attribute_name: kind,
        resolvable_class_name: 'Shipment',
        resolvable_class_since_attribute_name: 'dispatched_at',
        resolves_when_class_attribute_is: 'blank_false',
      )
    end
  end
end
