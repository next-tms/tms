class CreateDelays < ActiveRecord::Migration[6.0]
  def change
    create_table :delays do |t|
      t.string :title
      t.text :notes
      t.references :shipment, null: false, foreign_key: true
      t.timestamps
    end
  end
end
