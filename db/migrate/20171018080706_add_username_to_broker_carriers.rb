class AddUsernameToBrokerCarriers < ActiveRecord::Migration[5.1]
  def change
    add_column :broker_carriers, :username, :string
  end
end
