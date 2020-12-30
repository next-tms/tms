class AddCanQuoteToBrokerCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_customers, :can_quote, :boolean, default: false
  end
end
