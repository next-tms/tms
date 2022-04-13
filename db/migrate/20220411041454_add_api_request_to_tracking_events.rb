# frozen_string_literal: true

class AddApiRequestToTrackingEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :tracking_events, :api_request, :text
  end
end
