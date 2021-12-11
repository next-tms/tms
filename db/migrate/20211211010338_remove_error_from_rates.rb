# frozen_string_literal: true

class RemoveErrorFromRates < ActiveRecord::Migration[6.1]
  def change
    remove_column :rates, :error, :text
  end
end
