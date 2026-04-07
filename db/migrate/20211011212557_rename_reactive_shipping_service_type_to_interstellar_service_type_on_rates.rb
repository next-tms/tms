class RenameReactiveShippingServiceTypeToInterstellarServiceTypeOnRates < ActiveRecord::Migration[6.1]
  def change
    rename_column :rates, :reactive_shipping_service_type, :interstellar_service_type
  end
end
