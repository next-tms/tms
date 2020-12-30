class AddCustomerNotesToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :customer_notes, :text
  end
end
