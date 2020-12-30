class AddEnableAutoFreightClassToBrokerCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_customers, :enable_auto_freight_class, :boolean, default: true
  end
end
