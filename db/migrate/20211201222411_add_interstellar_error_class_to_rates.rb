# frozen_string_literal: true

class AddInterstellarErrorClassToRates < ActiveRecord::Migration[6.1]
  def change
    add_column :rates, :interstellar_error_class, :string
  end
end
