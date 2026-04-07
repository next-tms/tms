class ChangeNullOnBrokerCustomersPrimaryPickupAddressId < ActiveRecord::Migration[7.0]
  def up
    say 'populate(:broker_customers, :primary_pickup_address_id)'
    Broker.all.find_each do |broker|
      address = broker.address

      broker.broker_customers.where(primary_pickup_address_id: nil).find_each do |broker_customer|
        broker_customer.primary_pickup_address = address.dup
        broker_customer.save
      end
    end

    change_column_null :broker_customers, :primary_pickup_address_id, false
  end

  def down
    change_column_null :broker_customers, :primary_pickup_address_id, true
  end
end
