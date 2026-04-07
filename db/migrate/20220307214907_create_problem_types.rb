class CreateProblemTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :problem_types do |t|
      t.string :name, index: true, unique: true

      t.timestamps
    end
  end
end
