# frozen_string_literal: true

class RemoveLegacyTimeZoneFromAddresses < ActiveRecord::Migration[6.1]
  def change
    remove_column :addresses, :legacy_time_zone, :string
  end
end
