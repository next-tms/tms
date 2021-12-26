# frozen_string_literal: true

class AddErrorObjectToPickups < ActiveRecord::Migration[6.1]
  def change
    add_column :pickups, :error_object, :text
  end
end
