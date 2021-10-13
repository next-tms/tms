# frozen_string_literal: true

class CreatePickups < ActiveRecord::Migration[6.1]
  def change
    create_table :pickups do |t|
      t.datetime :confirmed_at
      t.datetime :requested_at
      t.references :rate, null: false, foreign_key: true
      t.references :shipment, null: false, foreign_key: true
      t.references :updated_by, null: true, foreign_key: { to_table: :users }
      t.string :error
      t.string :pickup_confirmation
      t.string :pro

      t.timestamps
    end
  end
end
