# frozen_string_literal: true

class AddRequiresCarrierPodOnReceivablesToBrokerCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :broker_customers, :requires_carrier_pod_on_receivables, :boolean, default: true
  end
end
