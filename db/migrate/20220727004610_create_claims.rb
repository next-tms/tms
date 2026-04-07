class CreateClaims < ActiveRecord::Migration[7.0]
  def change
    create_table :claims do |t|
      t.references :shipment, null: false, foreign_key: true

      t.date :due_on, index: true

      t.monetize :balance
      t.monetize :total

      t.timestamps
    end
  end
end
