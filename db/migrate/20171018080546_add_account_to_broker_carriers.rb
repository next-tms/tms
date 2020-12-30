class AddAccountToBrokerCarriers < ActiveRecord::Migration[5.1]
  def change
    add_column :broker_carriers, :account, :string
  end
end
