# frozen_string_literal: true

class AddResolvesWhenClassAttributeIsToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :resolves_when_class_attribute_is, :string, index: true
  end
end
