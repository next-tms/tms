# frozen_string_literal: true

class RenameTimeZoneToLegacyTimeZoneOnAddresses < ActiveRecord::Migration[6.1]
  def change
    rename_column :addresses, :time_zone, :legacy_time_zone
  end
end
