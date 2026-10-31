class RemoveFreightClassFromItems < ActiveRecord::Migration[5.1]
  def up
    remove_column :items, :freight_class
  end
end
