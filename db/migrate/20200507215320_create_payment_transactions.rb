class CreatePaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :payment_transactions do |t|
      t.references :shipment, null: true, foreign_key: true
      t.string :pro
      t.monetize :balance
      t.monetize :paid
      t.text :notes
      t.timestamps
    end
  end
end
