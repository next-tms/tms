class AddForcedClassToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :forced_class, :float
  end
end
