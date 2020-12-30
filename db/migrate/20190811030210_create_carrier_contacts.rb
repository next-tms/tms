class CreateCarrierContacts < ActiveRecord::Migration[5.1]
  def change
    create_table :carrier_contacts do |t|
      t.references :broker, foreign_key: true
      t.references :carrier, foreign_key: true
      t.references :contact, foreign_key: true
    end
  end
end
