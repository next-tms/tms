class AddHasTraceablePickupConfirmationToCarriers < ActiveRecord::Migration[6.0]
  def change
    add_column :carriers, :has_traceable_pickup_confirmation, :boolean, default: false
  end
end
