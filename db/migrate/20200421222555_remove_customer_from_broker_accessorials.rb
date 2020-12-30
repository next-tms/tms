class RemoveCustomerFromBrokerAccessorials < ActiveRecord::Migration[6.0]
  def change
    remove_column :broker_accessorials, :customer_id
  end
end
