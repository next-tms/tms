# frozen_string_literal: true

class AddCompanyableToUsers < ActiveRecord::Migration[7.0]
  def up
    add_reference(:users, :companyable, polymorphic: true)

    say('populate(:users, :companyable)')
    User.where(broker_customer_id: nil).update_all(companyable_id: Broker.first.id, companyable_type: 'Broker')
    User.where.not(broker_customer_id: nil).find_each do |record|
      record.update_columns(companyable_id: record.broker_customer_id, companyable_type: 'BrokerCustomer')
    end

    change_column_null(:users, :companyable_id, false)
    change_column_null(:users, :companyable_type, false)

    remove_column(:users, :broker_customer_id)
  end

  def down
    add_reference(:users, :broker_customer, foreign_key: true, null: true)

    say('populate(:users, :broker_customer_id)')
    User.includes(:company).where(companyable_type: 'BrokerCustomer').find_each do |record|
      record.update_columns(broker_customer_id: record.company.id)
    end

    remove_column(:users, :companyable_id)
    remove_column(:users, :companyable_type)
  end
end
