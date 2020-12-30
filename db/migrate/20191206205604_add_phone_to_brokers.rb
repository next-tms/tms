class AddPhoneToBrokers < ActiveRecord::Migration[5.1]
  def change
    add_column :brokers, :phone, :string
  end
end
