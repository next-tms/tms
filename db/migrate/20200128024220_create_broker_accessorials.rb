class CreateBrokerAccessorials < ActiveRecord::Migration[6.0]
  def change
    create_table :broker_accessorials do |t|
      t.references :broker, null: false, foreign_key: true
      t.references :customer, default: nil, foreign_key: true
      t.references :accessorial, default: nil, foreign_key: true
      t.string :name
      t.float :cost
      t.float :upcharge
      t.float :upcharge_percent
    end
  end
end
