class AddQuotedDeliveryByToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :quoted_delivery_by, :datetime
  end
end
