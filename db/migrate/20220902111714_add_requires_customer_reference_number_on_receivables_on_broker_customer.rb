class AddRequiresCustomerReferenceNumberOnReceivablesOnBrokerCustomer < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_customers, :requires_customer_reference_number_on_receivables, :boolean, default: false
  end
end
