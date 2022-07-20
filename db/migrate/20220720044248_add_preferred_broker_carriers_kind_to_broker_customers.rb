# frozen_string_literal: true

class AddPreferredBrokerCarriersKindToBrokerCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_customers, :preferred_broker_carriers_kind, :string, index: true
  end
end
