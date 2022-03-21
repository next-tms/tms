# frozen_string_literal: true

class AddCodeToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :code, :string, index: true, null: false
  end
end
