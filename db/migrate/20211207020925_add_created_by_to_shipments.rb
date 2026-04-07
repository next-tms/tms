class AddCreatedByToShipments < ActiveRecord::Migration[6.1]
  def change
    add_reference :shipments, :created_by, null: true, foreign_key: { to_table: :users }
  end
end
