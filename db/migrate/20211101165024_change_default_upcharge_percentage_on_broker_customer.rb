# frozen_string_literal: true

class ChangeDefaultUpchargePercentageOnBrokerCustomer < ActiveRecord::Migration[6.1]
  def up
    change_column_default :broker_customers, :default_upcharge_percentage, 0
  end

  def down
    change_column_default :broker_customers, :default_upcharge_percentage, nil
  end
end
