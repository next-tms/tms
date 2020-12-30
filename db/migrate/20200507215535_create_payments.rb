class CreatePayments < ActiveRecord::Migration[6.0]
  def change
    create_table :payments do |t|
      t.references :broker_carrier, null: false, foreign_key: true
      t.string :method
      t.string :method_reference
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.timestamps
    end
  end
end
