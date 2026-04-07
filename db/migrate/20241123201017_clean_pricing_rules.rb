class CleanPricingRules < ActiveRecord::Migration[7.1]
  def up
    PricingRule.where(cost_per_pallet_cents: 0).delete_all
  end

  def down; end
end
