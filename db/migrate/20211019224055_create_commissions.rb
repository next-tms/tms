class CreateCommissions < ActiveRecord::Migration[6.1]
  def change
    create_table :commissions do |t|
      t.boolean :paid, default: false

      t.monetize :amount

      t.references :broker_customer_sales_rep, null: false, foreign_key: true
      t.references :shipment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
