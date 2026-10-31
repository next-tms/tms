class AddReceivablesScheduleToBrokerCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_customers, :receivables_schedule, :string, default: 'immediately'
    add_index :broker_customers, :receivables_schedule
  end
end
