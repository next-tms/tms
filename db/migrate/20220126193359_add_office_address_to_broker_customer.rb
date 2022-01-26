# frozen_string_literal: true

class AddOfficeAddressToBrokerCustomer < ActiveRecord::Migration[7.0]
  def up
    add_reference :broker_customers, :office_address, foreign_key: { to_table: :addresses }

    say 'populate(:broker_customers, :office_address)'
    BrokerCustomer.all.find_each do |broker_customer|
      office_address = broker_customer.primary_pickup_address&.dup
      office_address = broker_customer.broker.address.dup if office_address.blank?
      office_address.save(validate: false)

      broker_customer.update_columns(office_address_id: office_address.id)
    end

    change_column_null :broker_customers, :office_address_id, false
  end

  def down
    Address.where(id: BrokerCustomer.all.pluck(:office_address_id)).delete_all

    remove_column :broker_customers, :office_address_id
  end
end
