# frozen_string_literal: true

class AddAPIErrorsToRates < ActiveRecord::Migration[7.0]
  def change
    add_column(:rates, :api_errors, :jsonb, default: '[]', null: false)
add_index :rates, :api_errors
  end
end
