class AddValidFreightClassesToBrokerCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_customers, :valid_freight_classes, :text
  end
end
