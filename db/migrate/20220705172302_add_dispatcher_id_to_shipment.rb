class AddDispatcherIdToShipment < ActiveRecord::Migration[7.0]
  def change
    add_reference :shipments, :dispatcher, null: true, foreign_key: { to_table: :users }
  end
end
