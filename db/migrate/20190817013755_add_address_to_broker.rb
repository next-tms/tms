class AddAddressToBroker < ActiveRecord::Migration[5.1]
  def change
    add_reference :brokers, :address, foreign_key: true
  end
end
