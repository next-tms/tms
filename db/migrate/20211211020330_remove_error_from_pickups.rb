class RemoveErrorFromPickups < ActiveRecord::Migration[6.1]
  def change
    remove_column :pickups, :error, :string
  end
end
