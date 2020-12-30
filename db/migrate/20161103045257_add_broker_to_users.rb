class AddBrokerToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :broker_id, :integer, foreign_key: true
  end
end
