# frozen_string_literal: true

class AddPublicByDefaultToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :public_by_default, :boolean, default: true, null: false
  end
end
