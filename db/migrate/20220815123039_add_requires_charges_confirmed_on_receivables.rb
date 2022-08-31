class AddRequiresChargesConfirmedOnReceivables < ActiveRecord::Migration[7.0]
  def change
    add_column :brokers, :requires_charges_confirmed_on_receivables, :boolean, default: false
    add_column :broker_customers, :requires_charges_confirmed_on_receivables, :boolean, default: false
  end
end
