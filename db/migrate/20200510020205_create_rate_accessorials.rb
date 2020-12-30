class CreateRateAccessorials < ActiveRecord::Migration[6.0]
  def change
    create_table :rate_accessorials do |t|
      t.references :rate, null: false, foreign_key: true
      t.references :accessorial, null: false, foreign_key: true
      t.timestamps
    end
  end
end
