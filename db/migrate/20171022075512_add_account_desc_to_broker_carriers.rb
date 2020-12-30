class AddAccountDescToBrokerCarriers < ActiveRecord::Migration[5.1]
  def change
    add_column :broker_carriers, :account_desc, :string
  end
end
