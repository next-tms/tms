# frozen_string_literal: true

class RenameTimeZoneToLegacyTimeZoneOnUsers < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :time_zone, :legacy_time_zone
  end
end
