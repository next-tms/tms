# frozen_string_literal: true

class AddSourceToRates < ActiveRecord::Migration[7.0]
  def change
    add_column :rates, :source, :string
add_index :rates, :source
  end
end
