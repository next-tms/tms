class DropBrokerCustomerReceivableContacts < ActiveRecord::Migration[7.0]
  def up
    say('populate(:broker_customers, :receivables_contact_id)')
    BrokerCustomerReceivableContact.includes(:broker_customer).find_each do |broker_customer_receivable_contact|
      broker_customer_receivable_contact.broker_customer.update!(receivables_contact_id: broker_customer_receivable_contact.contact_id)
    end

    drop_table(:broker_customer_receivable_contacts)
  end

  def down
    create_table('broker_customer_receivable_contacts', force: :cascade) do |t|
      t.bigint('broker_customer_id', null: false)
      t.bigint('contact_id', null: false)
      t.boolean('primary')
      t.datetime('created_at', null: false)
      t.datetime('updated_at', null: false)
      t.index(['broker_customer_id'], name: 'index_broker_customer_receivable_contacts_on_broker_customer_id')
      t.index(['contact_id'], name: 'index_broker_customer_receivable_contacts_on_contact_id')
    end

    say('populate(:broker_customer_receivable_contacts)')
    BrokerCustomer.find_each do |broker_customer|
      BrokerCustomerReceivableContact.create!(broker_customer_id: broker_customer, contact_id: receivables_contact_id, primary: true)
    end
  end
end
