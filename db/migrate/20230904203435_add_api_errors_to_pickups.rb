# frozen_string_literal: true

class AddAPIErrorsToPickups < ActiveRecord::Migration[7.0]
  def change
    add_column(:pickups, :api_errors, :jsonb, index: true, default: '[]', null: false)
  end
end
