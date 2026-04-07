class AddIndexToNameOnCarriers < ActiveRecord::Migration[7.0]
  def change
    add_index :carriers, :name, unique: true
  end
end
