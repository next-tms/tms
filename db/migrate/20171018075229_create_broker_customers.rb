class CreateBrokerCustomers < ActiveRecord::Migration[5.1]
  def change
    create_table :broker_customers do |t|
      t.belongs_to :customer, foreign_key: true
      t.belongs_to :broker, foreign_key: true

      t.timestamps
    end
  end
end
