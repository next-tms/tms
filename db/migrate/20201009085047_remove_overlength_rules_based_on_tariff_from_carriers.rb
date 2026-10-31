class RemoveOverlengthRulesBasedOnTariffFromCarriers < ActiveRecord::Migration[6.0]
  def up
    remove_column :carriers, :overlength_rules_based_on_tariff
  end
end
