# frozen_string_literal: true

class ChangeDefaultUpchargePercentageOnUpchargeRules < ActiveRecord::Migration[6.1]
  def up
    change_column_default :upcharge_rules, :upcharge_percentage, 0
  end

  def down
    change_column_default :upcharge_rules, :upcharge_percentage, nil
  end
end
