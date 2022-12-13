class AddNotNullConstraintOnShipmentDispatcher < ActiveRecord::Migration[7.0]
  def change
    Shipment.where(dispatcher_id: nil).find_each do |s|
      s.assign_dispatcher
      s.update_columns(dispatcher_id: s.dispatcher_id)
      print '*'
      # Use update_columns to prevent any active record callback actions from triggerring
    end
    change_column :shipments, :dispatcher_id, :bigint, null: false
  end
end
