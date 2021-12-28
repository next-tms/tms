# frozen_string_literal: true

class RemoveTimeZoneFromBrokers < ActiveRecord::Migration[7.0]
  def change
    remove_column :brokers, :time_zone, :string
  end
end
