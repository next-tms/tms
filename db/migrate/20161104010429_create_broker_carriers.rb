class CreateBrokerCarriers < ActiveRecord::Migration[5.0]
  def change
    create_table :broker_carriers do |t|
      t.belongs_to :carrier, foreign_key: true
      t.belongs_to :broker, foreign_key: true

      t.timestamps
    end
  end
end
