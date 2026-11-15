class AddNameToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :name, :string
  end
end
