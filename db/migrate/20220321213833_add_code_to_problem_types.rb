class AddCodeToProblemTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :problem_types, :code, :string, null: false
add_index :problem_types, :code
  end
end
