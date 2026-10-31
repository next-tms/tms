class AddResolvableClassNameToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :resolvable_class_name, :string
    add_index :problem_types, :resolvable_class_name
  end
end
