class AddResolvableClassAttributeNameToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :resolvable_class_attribute_name, :string
add_index :problem_types, :resolvable_class_attribute_name
  end
end
