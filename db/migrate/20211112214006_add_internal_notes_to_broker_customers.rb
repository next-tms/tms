class AddInternalNotesToBrokerCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :broker_customers, :internal_notes, :text
  end
end
