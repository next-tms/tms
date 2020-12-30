class CreateBrokerCustomerSalesReps < ActiveRecord::Migration[6.0]
  def change
    create_table :broker_customer_sales_reps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :broker_customer, null: false, foreign_key: true
      t.timestamps
    end
  end
end
