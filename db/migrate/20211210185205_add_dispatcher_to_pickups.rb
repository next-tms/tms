# frozen_string_literal: true

class AddDispatcherToPickups < ActiveRecord::Migration[6.1]
  def change
    add_reference :pickups, :dispatcher, null: true, foreign_key: { to_table: :users }
  end
end
