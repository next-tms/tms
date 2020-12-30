class AddDefaultBolNotesToBrokerCarrier < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_carriers, :default_bol_notes, :text
  end
end
