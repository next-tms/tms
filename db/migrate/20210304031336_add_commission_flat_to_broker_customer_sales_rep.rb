class AddCommissionFlatToBrokerCustomerSalesRep < ActiveRecord::Migration[6.0]
  def change
    add_monetize :broker_customer_sales_reps, :commission_flat
  end
end
