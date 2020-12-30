class AddDeliveryAppointmentOnToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :delivery_appointment_on, :date
  end
end
