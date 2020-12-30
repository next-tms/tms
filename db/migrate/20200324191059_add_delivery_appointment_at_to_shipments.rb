class AddDeliveryAppointmentAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :delivery_appointment_at, :datetime
  end
end
