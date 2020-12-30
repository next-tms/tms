class AddBrokerOnlyToBrokerAccessorials < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_accessorials, :broker_only, :boolean, default: true
  end
end
