class RemoveAPIConfiguredFromBrokerCarriers < ActiveRecord::Migration[7.0]
  def change
    remove_column(:broker_carriers, :api_configured, :boolean)
  end
end
