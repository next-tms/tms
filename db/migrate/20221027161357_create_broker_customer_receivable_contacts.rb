class CreateBrokerCustomerReceivableContacts < ActiveRecord::Migration[7.0]
  def up
    create_table :broker_customer_receivable_contacts do |t|
      t.references :broker_customer, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.boolean :primary

      t.timestamps
    end

    BrokerCustomer.find_each do |broker_customer|
      next if broker_customer.receivables_contact_id.blank?

      BrokerCustomerReceivableContact.create(
        broker_customer:,
        contact_id: broker_customer.receivables_contact_id,
        primary: true
      )
    end
  end

  def down
    drop_table :broker_customer_receivable_contacts
  end
end
