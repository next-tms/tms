class RemoveNotNullConstraintOnBrokerCustomerReceivablesContactId < ActiveRecord::Migration[7.0]
  def change
    change_column_null :broker_customers, :receivables_contact_id, true
  end
end
