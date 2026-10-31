class AddBrokerLoadIdUniqueIndexOnShipments < ActiveRecord::Migration[6.1]
  def change
    add_index :shipments, %i[broker_id load_id], unique: true
  end
end
