# frozen_string_literal: true

class DropRoles < ActiveRecord::Migration[7.0]
  def change
    drop_table('roles', force: :cascade) do |t|
      t.string('name')
      t.datetime('created_at', null: false)
      t.datetime('updated_at', null: false)
    end
  end
end
