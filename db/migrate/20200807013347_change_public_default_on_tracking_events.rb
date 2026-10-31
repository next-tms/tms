class ChangePublicDefaultOnTrackingEvents < ActiveRecord::Migration[6.0]
  def up
    change_column_default :tracking_events, :public, true
  end
end
