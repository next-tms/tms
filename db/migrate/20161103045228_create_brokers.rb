class CreateBrokers < ActiveRecord::Migration[5.0]
  def change
    create_table :brokers do |t|
      t.string :name
    end
  end
end
