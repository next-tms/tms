# frozen_string_literal: true

class PopulateSuppressors < ActiveRecord::Migration[7.0]
  def up
    say 'populate(:suppressors)'
    [ Broker, BrokerCustomer ].each do |model|
      model.all.find_each { |record| record.send(:update_suppressors) }
    end
  end

  def down; end
end
