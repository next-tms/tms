class AddFlatChargeToBrokerAccessorials < ActiveRecord::Migration[6.0]
  def change
    add_monetize :broker_accessorials, :flat_charge
  end
end
