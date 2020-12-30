class AddStateToTrackingEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :tracking_events, :state, :string
  end
end
