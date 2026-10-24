class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table(:reports) do |t|
      t.references :created_by, foreign_key: { to_table: :users }, null: false, type: :integer

      t.jsonb :columns, default: [], null: false
      t.string :date_attribute
      t.jsonb :filters, default: {}, null: false
      t.string :name, index: { unique: true }, null: false
      t.string :record_type, null: false

      t.timestamps
    end
  end
end
