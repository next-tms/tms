class CreateReceivables < ActiveRecord::Migration[6.1]
  def change
    create_table :receivables do |t|
      t.boolean :invoiced, default: false, index: true
      t.datetime :authorized_at, index: true
      t.datetime :due_by, index: true
      t.datetime :paid_at, index: true
      t.references :authorized_by, null: true, foreign_key: { to_table: :users }
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.references :shipment, null: false, foreign_key: true
      t.references :updated_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
