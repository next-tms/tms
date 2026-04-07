class RemoveBrokerIdFromContacts < ActiveRecord::Migration[7.0]
  def change
    remove_column :contacts, :broker_id, :bigint
  end
end
