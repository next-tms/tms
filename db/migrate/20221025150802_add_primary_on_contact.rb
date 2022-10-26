class AddPrimaryOnContact < ActiveRecord::Migration[7.0]
  def up
    add_column :contacts, :primary, :boolean, default: false

    BrokerCustomer.all.find_each do |broker_customer|
      next unless broker_customer.receivables_contact_id

      primary_contact = Contact.find(broker_customer.receivables_contact_id)
      primary_contact.update_columns(broker_customer_id: broker_customer.id, primary: true)
    end
  end

  def down
    BrokerCustomer.all.find_each do |broker_customer|
      next unless broker_customer.primary_receivables_contact.present?

      broker_customer.update_columns(receivables_contact_id: broker_customer.primary_receivables_contact.id)
    end

    remove_column :contacts, :primary
  end
end
