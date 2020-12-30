class AddCommentsToContacts < ActiveRecord::Migration[5.1]
  def change
    add_column :contacts, :comments, :text
  end
end
