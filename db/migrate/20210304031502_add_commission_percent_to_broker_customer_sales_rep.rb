class AddCommissionPercentToBrokerCustomerSalesRep < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_customer_sales_reps, :commission_percent, :decimal, default: 0
  end
end
