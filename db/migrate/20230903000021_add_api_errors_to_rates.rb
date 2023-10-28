# frozen_string_literal: true

class AddAPIErrorsToRates < ActiveRecord::Migration[7.0]
  def change
    add_column(:rates, :api_errors, :jsonb, index: true, default: '[]', null: false)
  end
end
