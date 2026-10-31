class DropCustomerContacts < ActiveRecord::Migration[7.0]
  def change
    drop_table('customer_contacts', force: :cascade) do |t|
      t.bigint('broker_id')
      t.bigint('customer_id')
      t.bigint('contact_id')
      t.index(['broker_id'], name: 'index_customer_contacts_on_broker_id')
      t.index(['contact_id'], name: 'index_customer_contacts_on_contact_id')
      t.index(['customer_id'], name: 'index_customer_contacts_on_customer_id')
    end
  end
end
