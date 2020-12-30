class ChangePublicDefaultOnTrackingEvents < ActiveRecord::Migration[6.0]
  def change
    change_column_default :tracking_events, :public, true
  end
end
