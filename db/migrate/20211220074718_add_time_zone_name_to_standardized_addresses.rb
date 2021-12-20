# frozen_string_literal: true

class AddTimeZoneNameToStandardizedAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :standardized_addresses, :time_zone_name, :string, index: true, null: false
  end
end
