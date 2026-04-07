class RemoveStateFromTrackingEvents < ActiveRecord::Migration[6.1]
  def change
    remove_column :tracking_events, :state, :string
  end
end
