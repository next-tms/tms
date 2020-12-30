class AddUserToTrackingEvents < ActiveRecord::Migration[6.0]
  def change
    add_reference :tracking_events, :user, null: true, foreign_key: true
  end
end
