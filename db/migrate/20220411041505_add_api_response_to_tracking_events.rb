# frozen_string_literal: true

class AddApiResponseToTrackingEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :tracking_events, :api_response, :text
  end
end
