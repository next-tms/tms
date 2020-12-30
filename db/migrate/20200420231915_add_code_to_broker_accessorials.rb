class AddCodeToBrokerAccessorials < ActiveRecord::Migration[6.0]
  def change
    add_column :broker_accessorials, :code, :string
  end
end
