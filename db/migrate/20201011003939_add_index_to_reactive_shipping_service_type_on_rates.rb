class AddIndexToReactiveShippingServiceTypeOnRates < ActiveRecord::Migration[6.0]
  def change
    add_index :rates, :reactive_shipping_service_type
  end
end
