class CreateBrokerCountries < ActiveRecord::Migration[6.1]
  def change
    create_table :broker_countries do |t|
      t.references :broker
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end
  end
end
