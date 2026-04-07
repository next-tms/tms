class RenameDeliverByToDeliveryEtaOnOnShipments < ActiveRecord::Migration[6.1]
  def change
    rename_column :shipments, :deliver_by, :delivery_eta_on
  end
end
