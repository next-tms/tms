# frozen_string_literal: true

class AddRequiresCarrierBolOnReceivablesToBrokerCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :broker_customers, :requires_carrier_bol_on_receivables, :boolean, default: true
    add_index :broker_customers, :requires_carrier_bol_on_receivables
  end
end
