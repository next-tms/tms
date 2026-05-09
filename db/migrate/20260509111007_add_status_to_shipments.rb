class AddStatusToShipments < ActiveRecord::Migration[8.0]
  class Shipment < ApplicationRecord
    self.table_name = 'shipments'
  end

  def up
    add_column :shipments, :status, :string

    Shipment.find_each { |record| record.update_column(:status, status(record)) }

    change_column_null :shipments, :status, false

    add_index :shipments, :status
  end

  def down = remove_column(:shipments, :status)

  private

  def status(shipment)
    if shipment.canceled_at.present?
      'canceled'
    elsif shipment.delivered_at.present?
      'delivered'
    elsif shipment.out_for_delivery_at.present?
      'out_for_delivery'
    elsif shipment.delivery_appointment_at.present? || shipment.delivery_appointment_on.present?
      'delivery_scheduled'
    elsif shipment.pending_appointment_since.present?
      'pending_delivery_appointment'
    elsif shipment.picked_up_at.present?
      'in_transit'
    elsif shipment.pickup_confirmation.present? && shipment.pickup_on.present? && shipment.pickup_hours_end_at.present?
      'pickup_scheduled'
    elsif shipment.dispatched_at.present?
      'dispatched'
    elsif shipment.booked_at.present? && shipment.total_charges_cents.to_i > 0
      'booked_quoted'
    elsif shipment.total_charges_cents.to_i > 0
      'quoted'
    elsif shipment.booked_at.present?
      'booked'
    else
      'new_shipment'
    end
  end
end
