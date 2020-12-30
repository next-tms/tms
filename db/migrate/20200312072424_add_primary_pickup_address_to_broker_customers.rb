class AddPrimaryPickupAddressToBrokerCustomers < ActiveRecord::Migration[6.0]
  def change
    add_reference :broker_customers, :primary_pickup_address, foreign_key: { to_table: :addresses }
  end
end
