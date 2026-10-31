class PopulateSuppressors < ActiveRecord::Migration[7.0]
  def up
    say 'populate(:suppressors)'
    [Broker, BrokerCustomer].each { |model| model.find_each { |record| record.__send__(:update_suppressors) } }
  end

  def down; end
end
