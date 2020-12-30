class AddUpdatedByToShipments < ActiveRecord::Migration[6.0]
  def change
    add_reference :shipments, :updated_by, foreign_key: { to_table: :users }
  end
end
