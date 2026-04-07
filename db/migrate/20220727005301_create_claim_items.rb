class CreateClaimItems < ActiveRecord::Migration[7.0]
  def change
    create_table :claim_items do |t|
      t.references :claim, null: false, foreign_key: true
      t.references :payee, polymorphic: true, null: false

      t.monetize :balance
      t.monetize :total

      t.text :notes

      t.timestamps
    end
  end
end
