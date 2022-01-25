# frozen_string_literal: true

class AddQuickbooksCustomerIdToBrokerCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_customers, :quickbooks_customer_id, :string, index: true
  end
end
