class AddDefaultBolNotesToBroker < ActiveRecord::Migration[6.0]
  def change
    add_column :brokers, :default_bol_notes, :text
  end
end
