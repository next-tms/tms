# frozen_string_literal: true

class AddTimeZoneNameToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :time_zone_name, :string

    say 'Populate users.time_zone_name'
    User.all.find_each do |user|
      next unless user.legacy_time_zone.is_a?(Timezone::Zone)
      user.update_columns(time_zone_name: user.legacy_time_zone.name)
    end

    User.where(time_zone_name: nil).update_all(time_zone_name: 'America/Los_Angeles')

    change_column_null :users, :time_zone_name, false
  end

  def down
    remove_column :users, :time_zone_name
  end
end
