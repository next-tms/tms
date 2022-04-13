# frozen_string_literal: true

class AddApiRequestToPickups < ActiveRecord::Migration[7.0]
  def change
    add_column :pickups, :api_request, :text
  end
end
