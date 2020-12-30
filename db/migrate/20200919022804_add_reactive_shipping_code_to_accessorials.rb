class AddReactiveShippingCodeToAccessorials < ActiveRecord::Migration[6.0]
  def change
    add_column :accessorials, :reactive_shipping_code, :string
  end
end
