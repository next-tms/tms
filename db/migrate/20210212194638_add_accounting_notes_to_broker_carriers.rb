class AddAccountingNotesToBrokerCarriers < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_carriers, :accounting_notes, :text
  end
end
