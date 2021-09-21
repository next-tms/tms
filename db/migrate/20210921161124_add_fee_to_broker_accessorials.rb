# frozen_string_literal: true

class AddFeeToBrokerAccessorials < ActiveRecord::Migration[6.1]
  def change
    add_column :broker_accessorials, :fee, :boolean, default: false
  end
end
