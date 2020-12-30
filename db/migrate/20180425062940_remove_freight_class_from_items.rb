class RemoveFreightClassFromItems < ActiveRecord::Migration[5.1]
  def change
    remove_column :items, :freight_class
  end
end
