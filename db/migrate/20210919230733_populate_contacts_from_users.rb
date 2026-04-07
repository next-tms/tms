# frozen_string_literal: true

class PopulateContactsFromUsers < ActiveRecord::Migration[6.1]
  def up
    User.all.includes(:broker, :broker_customer).find_each do |user|
      contact = Contact.create(
        broker_customer: user.broker_customer,
        broker: user.broker,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name
      )

      user.update_columns(contact_id: contact.id)
    end
  end

  def down; end
end
