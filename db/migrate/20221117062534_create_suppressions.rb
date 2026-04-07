class CreateSuppressions < ActiveRecord::Migration[7.0]
  def change
    create_table :suppressions do |t|
      t.datetime :ignored_at

      t.references :ignored_by, null: true, foreign_key: { to_table: :users }
      t.references :instigator, null: false, polymorphic: true
      t.references :problem, foreign_key: true, null: false
      t.references :problematic, null: false, polymorphic: true
      t.references :suppressor, foreign_key: true, null: false

      t.string :suppressible_type, index: true, null: false

      t.timestamps
    end
  end
end
