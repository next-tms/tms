# frozen_string_literal: true

class AddAPIConfiguredToBrokerCarriers < ActiveRecord::Migration[7.0]
  def up
    add_column :broker_carriers, :api_configured, :boolean, default: false

    say 'populate(:broker_carriers, :api_configured)'
    BrokerCarrier.find_each do |broker_carrier|
      broker_carrier.send(:set_api_configured)
      next unless broker_carrier.api_configured_changed?

      broker_carrier.update_columns(api_configured: broker_carrier.api_configured)
    end
  end

  def down
    remove_column :broker_carriers, :api_configured
  end
end
