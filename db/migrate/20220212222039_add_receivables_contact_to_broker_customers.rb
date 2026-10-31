class AddReceivablesContactToBrokerCustomers < ActiveRecord::Migration[7.0]
  def up
    add_reference :broker_customers, :receivables_contact, null: true, foreign_key: { to_table: :contacts }

    say 'populate(:broker_customers, :receivables_contact_id)'

    BrokerCustomer.find_each do |broker_customer|
      if broker_customer.contacts.size == 1
        broker_customer.update_columns(receivables_contact_id: broker_customer.contacts.first.id)
        next
      end

      contact = Contact.create(
        email: "nobody+#{(rand * 1000).round}_#{DateTime.current.utc.to_i}@example.com",
        first_name: 'Nobody',
        last_name: 'Nobody'
      )
      broker_customer.update_columns(receivables_contact_id: contact.id)

      sleep(1) # to ensure unique Contact#email
    end

    change_column_null :broker_customers, :receivables_contact_id, false
  end

  def down
    remove_column :broker_customers, :receivables_contact_id
  end
end
