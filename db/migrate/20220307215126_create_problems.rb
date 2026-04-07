class CreateProblems < ActiveRecord::Migration[7.0]
  def change
    create_table :problems do |t|
      t.datetime :resolved_at, index: true

      t.references :assigned_to, null: false, foreign_key: { to_table: :users }
      t.references :problem_type, null: false, foreign_key: true
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.references :shipment, null: false, foreign_key: true

      t.string :title, index: true

      t.text :body, index: true

      t.timestamps
    end
  end
end
