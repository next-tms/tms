class RemovePerPalletRateCentsFromCarrierArea < ActiveRecord::Migration[6.0]
  def up
    remove_column :carrier_areas, :per_pallet_rate_cents
    remove_column :carrier_areas, :per_pallet_rate_currency
  end
end
