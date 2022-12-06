# frozen_string_literal: true

class AddIgnoreValueOnAPIQuotesToBrokerCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_customers, :ignore_value_on_api_quotes, :boolean, default: false
  end
end
