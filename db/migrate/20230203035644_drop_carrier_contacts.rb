class DropCarrierContacts < ActiveRecord::Migration[7.0]
  def up
    drop_table :carrier_contacts
  end

  def down
    create_table 'carrier_contacts', force: :cascade do |t|
      t.reference :broker
      t.reference :carrier
      t.reference :contact
    end

    broker = Broker.first
    Contact.where(company_type: 'Carrier').find_each do |record|
      CarrierContact.create!(broker:, carrier_id: record.company_id, contact: record)
    end
  end
end
