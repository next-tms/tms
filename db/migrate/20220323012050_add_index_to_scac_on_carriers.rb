class AddIndexToScacOnCarriers < ActiveRecord::Migration[7.0]
  def change
    add_index :carriers, :scac, unique: true
  end
end
