class AddReactiveShippingServiceTypeToRates < ActiveRecord::Migration[6.0]
  def change
    add_column :rates, :reactive_shipping_service_type, :string
  end
end
