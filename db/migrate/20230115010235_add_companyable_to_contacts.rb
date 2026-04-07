class AddCompanyableToContacts < ActiveRecord::Migration[7.0]
  def up
    add_reference(:contacts, :companyable, polymorphic: true)

    say('populate(:contacts, :companyable)')

    # First to avoid collisions
    CarrierContact.includes(:contact).find_each do |record|
      record.contact.update_columns(companyable_id: record.carrier_id, companyable_type: 'Carrier')
    end

    Contact.where(companyable_id: nil).where(broker_carrier_id: nil, broker_customer_id: nil).find_each do |record|
      record.update_columns(companyable_id: 1, companyable_type: 'Broker')
    end

    Contact.where(companyable_id: nil).where.not(broker_carrier_id: nil).find_each do |record|
      record.update_columns(companyable_id: record.broker_carrier_id, companyable_type: 'BrokerCarrier')
    end

    Contact.where(companyable_id: nil).where.not(broker_customer_id: nil).find_each do |record|
      record.update_columns(companyable_id: record.broker_customer_id, companyable_type: 'BrokerCustomer')
    end

    change_column_null(:contacts, :companyable_id, false)

    remove_column(:contacts, :broker_carrier_id)
    remove_column(:contacts, :broker_customer_id)
  end

  def down
    add_reference(:contacts, :broker_carrier, foreign_key: true, null: true)
    add_reference(:contacts, :broker_customer, foreign_key: true, null: true)

    say('populate(:contacts, :broker_carrier_id)')
    Contact.where(companyable_type: 'BrokerCarrier').find_each do |record|
      record.update_columns(broker_carrier_id: record.companyable_id)
    end

    say('populate(:contacts, :broker_customer_id)')
    Contact.where(companyable_type: 'BrokerCustomer').find_each do |record|
      record.update_columns(broker_customer_id: record.companyable_id)
    end

    remove_column(:contacts, :companyable_id)
    remove_column(:contacts, :companyable_type)
  end
end
