class AddTimeZoneNameToAddresses < ActiveRecord::Migration[6.1]
  def up
    add_column :addresses, :time_zone_name, :string

    say 'Populate addresses.time_zone_name'
    Address.all.find_each do |address|
      next unless address.legacy_time_zone.is_a?(Timezone::Zone)
      address.update_columns(time_zone_name: address.legacy_time_zone.name)
    end
  end

  def down
    remove_column :addresses, :time_zone_name
  end
end
