class AddBookedAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :booked_at, :datetime
  end
end
