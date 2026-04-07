class ChangeDefaultUpchargeCentsOnUpchargeRules < ActiveRecord::Migration[6.1]
  def up
    change_column_default :upcharge_rules, :upcharge_cents, 0
  end

  def down
    change_column_default :upcharge_rules, :upcharge_cents, nil
  end
end
