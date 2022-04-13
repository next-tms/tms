# frozen_string_literal: true

class AddApiResponseToPickups < ActiveRecord::Migration[7.0]
  def change
    add_column :pickups, :api_response, :text
  end
end
