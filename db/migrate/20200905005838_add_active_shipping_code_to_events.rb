class AddActiveShippingCodeToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :active_shipping_code, :string
  end
end
