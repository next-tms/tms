# frozen_string_literal: true

class ChangeDefaultUpchargeCentsOnBrokerCustomer < ActiveRecord::Migration[6.1]
  def up
    change_column_default :broker_customers, :default_upcharge_cents, 0
  end

  def down
    change_column_default :broker_customers, :default_upcharge_cents, nil
  end
end
