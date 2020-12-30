class MonetizeUpchargeOnBrokerAccessorials < ActiveRecord::Migration[6.0]
  def change
    change_table :broker_accessorials do |t|
      t.monetize :upcharge
    end
  end
end
