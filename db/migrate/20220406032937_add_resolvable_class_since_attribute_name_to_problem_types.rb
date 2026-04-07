class AddResolvableClassSinceAttributeNameToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :resolvable_class_since_attribute_name, :string
  end
end
