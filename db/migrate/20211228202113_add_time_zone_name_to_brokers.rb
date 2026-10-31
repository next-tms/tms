class AddTimeZoneNameToBrokers < ActiveRecord::Migration[7.0]
  def up
    add_column :brokers, :time_zone_name, :string

    say 'Populate brokers.time_zone_name'
    Broker.update_all(time_zone_name: 'America/Los_Angeles')

    change_column_null :brokers, :time_zone_name, false
  end

  def down
    remove_column :brokers, :time_zone_name
  end
end
