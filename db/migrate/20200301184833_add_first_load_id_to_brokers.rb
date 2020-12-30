class AddFirstLoadIdToBrokers < ActiveRecord::Migration[6.0]
  def change
    add_column :brokers, :first_load_id, :int
  end
end
