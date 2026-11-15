class AddDockToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :dock, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
