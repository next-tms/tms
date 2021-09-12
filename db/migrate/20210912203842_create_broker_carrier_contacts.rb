class CreateBrokerCarrierContacts < ActiveRecord::Migration[6.1]
  def change
    create_table :broker_carrier_contacts do |t|
      t.references :broker_carrier, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.timestamps
    end
  end
end
