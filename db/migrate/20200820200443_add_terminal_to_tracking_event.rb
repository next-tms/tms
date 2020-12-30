class AddTerminalToTrackingEvent < ActiveRecord::Migration[6.0]
  def change
    add_reference :tracking_events, :terminal, null: true, foreign_key: true
  end
end
