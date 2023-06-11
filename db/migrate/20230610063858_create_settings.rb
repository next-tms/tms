# frozen_string_literal: true

class CreateSettings < ActiveRecord::Migration[7.0]
  def change
    create_table(:settings) do |t|
      t.string(:key, index: true, unique: true)
      t.string(:value)

      t.timestamps
    end
  end
end
