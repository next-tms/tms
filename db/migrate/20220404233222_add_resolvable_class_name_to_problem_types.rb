# frozen_string_literal: true

class AddResolvableClassNameToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :resolvable_class_name, :string, index: true
  end
end
