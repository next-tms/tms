class CreateTrackingEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :tracking_events do |t|
      t.references :shipment, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.boolean :public
      t.datetime :at
      t.string :time_zone
      t.timestamps
    end
  end
end
