class AddPendingAppointmentSinceToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :pending_appointment_since, :date
  end
end
