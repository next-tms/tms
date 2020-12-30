class AddTypesToAddresses < ActiveRecord::Migration[6.0]
  def change
    add_column :addresses, :types, :text
  end
end
