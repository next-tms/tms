class AddOverlengthRulesBasedOnTariffToCarriers < ActiveRecord::Migration[6.0]
  def change
    add_column :carriers, :overlength_rules_based_on_tariff, :boolean
  end
end
