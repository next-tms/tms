# frozen_string_literal: true

module Shipment::Problematic
  extend ActiveSupport::Concern

  included do
    def self.problematic_broker_carrier_id_blank
      active.pending_quotation
    end

    def self.problematic_carrier_bol_not_attached
      left_joins(:carrier_bol_blob)
        .where(broker_customer: BrokerCustomer.where(requires_carrier_bol_on_receivables: true))
        .where(id: Receivable.unpaid.unsent.pluck(:shipment_id))
        .where(active_storage_attachments: { id: nil })
    end

    def self.problematic_carrier_pod_not_attached
      left_joins(:carrier_pod_blob)
        .where(broker_customer: BrokerCustomer.where(requires_carrier_pod_on_receivables: true))
        .where(id: Receivable.unpaid.unsent.pluck(:shipment_id))
        .where(active_storage_attachments: { id: nil })
    end

    def self.problematic_delivery_appointment_on_blank
      pending_delivery.missing_delivery_appointment
    end

    def self.problematic_delivery_eta_on_blank
      pending_delivery.where(delivery_eta_on: [nil, ''])
    end

    def self.problematic_lost_on_not_blank
      where.not(lost_on: [nil, ''])
    end

    def self.problematic_picked_up_at_blank
      ids = pending_pickup.map do |shipment|
        shipment.id if shipment.pickup_on < DateTime.current.in_time_zone(shipment.shipper_address.time_zone).to_date
      end

      where(id: ids.compact)
    end

    def self.problematic_pickup_confirmation_blank
      ids = pending_pickup.where(pickup_confirmation: [nil, '']).map do |shipment|
        shipment.id if shipment.pickup_on <= DateTime.current.in_time_zone(shipment.shipper_address.time_zone).to_date
      end

      Shipment.where(id: ids.compact)
    end

    def self.problematic_pro_blank
      active.pending_delivery.where(pro: [nil, ''])
    end

    def self.problematic_tracking_carrier_pro_blank
      active.pending_delivery.where.not(tracking_carrier: nil).where(tracking_carrier_pro: [nil, ''])
    end

    def self.problematic_total_cost_cents_zero
      active.missing_cost
    end

    def self.problematic_total_charges_cents_zero
      active.missing_charge
    end
  end
end
