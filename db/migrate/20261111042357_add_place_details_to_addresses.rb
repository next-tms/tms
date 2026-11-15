class AddPlaceDetailsToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :business, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :addresses, :permanently_closed, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :addresses, :place_id, :string
    add_column :addresses, :po_box, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :addresses, :residential, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :addresses, :types, :string, array: true, default: [], null: false
    add_index :addresses, :place_id
  end
end
