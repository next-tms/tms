class AddResolvesWhenClassAttributeIsToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :resolves_when_class_attribute_is, :string
add_index :problem_types, :resolves_when_class_attribute_is
  end
end
