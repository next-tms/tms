class PopulateSuppressors < ActiveRecord::Migration[7.0]
  def up
    say 'populate(:suppressors)'
    [Broker, BrokerCustomer].each do |model|
      model.find_each { |record| record.__send__(:update_suppressors) }
    end
  end

  def down; end
end
