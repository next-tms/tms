class AddLabelToContacts < ActiveRecord::Migration[5.1]
  def change
    add_column :contacts, :label, :string
  end
end
