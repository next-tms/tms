class ResetBrokerCarriersCounters < ActiveRecord::Migration[6.1]
  def up
    BrokerCarrier.find_each { |broker_carrier| BrokerCarrier.reset_counters(broker_carrier.id, :shipments) }
  end
end
