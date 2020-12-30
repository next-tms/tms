class AddDefaultBolNotesToBrokerCustomer < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_customers, :default_bol_notes, :text
  end
end
