class AddCityToTrackingEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :tracking_events, :city, :string
  end
end
