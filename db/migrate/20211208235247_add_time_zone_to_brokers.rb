# frozen_string_literal: true

class AddTimeZoneToBrokers < ActiveRecord::Migration[6.1]
  def change
    add_column :brokers, :time_zone, :string
  end
end
