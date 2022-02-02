# frozen_string_literal: true

class AddBreakdownToRates < ActiveRecord::Migration[7.0]
  def change
    add_column :rates, :breakdown, :json
  end
end
