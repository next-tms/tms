# frozen_string_literal: true

class RemoveTimeZoneFromStandardizedAddresses < ActiveRecord::Migration[7.0]
  def change
    remove_column :standardized_addresses, :time_zone, :string
  end
end
