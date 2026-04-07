class ResetBrokerCarriersCounters < ActiveRecord::Migration[6.1]
  def up
    BrokerCarrier.all.find_each do |broker_carrier|
      BrokerCarrier.reset_counters(broker_carrier.id, :shipments)
    end
  end
end
