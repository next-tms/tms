class CreateTerminals < ActiveRecord::Migration[6.0]
  def change
    create_table :terminals do |t|
      t.references :address, null: false, foreign_key: true
      t.references :carrier, null: false, foreign_key: true
      t.string :phone
      t.timestamps
    end
  end
end
