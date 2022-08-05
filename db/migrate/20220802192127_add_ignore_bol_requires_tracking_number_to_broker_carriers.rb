# frozen_string_literal: true

class AddIgnoreBolRequiresTrackingNumberToBrokerCarriers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_carriers, :ignore_bol_requires_tracking_number, :boolean, default: false
  end
end
