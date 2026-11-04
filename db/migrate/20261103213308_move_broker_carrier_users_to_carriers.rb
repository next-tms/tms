class MoveBrokerCarrierUsersToCarriers < ActiveRecord::Migration[8.1]
  class BrokerCarrier < ActiveRecord::Base
    self.table_name = 'broker_carriers'
  end

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  def up
    BrokerCarrier.where(id: User.where(companyable_type: 'BrokerCarrier').select(:companyable_id)).find_each do |broker_carrier|
      User
        .where(companyable_id: broker_carrier.id, companyable_type: 'BrokerCarrier')
        .update_all(companyable_id: broker_carrier.carrier_id, companyable_type: 'Carrier')
    end
  end

  def down = raise(ActiveRecord::IrreversibleMigration)
end
