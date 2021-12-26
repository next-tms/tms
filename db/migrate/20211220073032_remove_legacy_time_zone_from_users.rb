# frozen_string_literal: true

class RemoveLegacyTimeZoneFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :legacy_time_zone, :string
  end
end
