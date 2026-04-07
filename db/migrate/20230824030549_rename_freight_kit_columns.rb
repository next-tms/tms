class RenameFreightKitColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column(:accessorials, :interstellar_code, :freight_kit_code)
    rename_column(:packagings, :interstellar_type, :freight_kit_type)
    rename_column(:rates, :interstellar_service_type, :freight_kit_service_type)
    rename_column(:tracking_events, :interstellar_carrier_fingerprint, :freight_kit_carrier_fingerprint)
  end
end
