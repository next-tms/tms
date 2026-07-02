class CreateIntegrationMappings < ActiveRecord::Migration[8.0]
  def change
    create_table(:integration_mappings) do |t|
      t.references :record, polymorphic: true, null: false, index: false
      t.references :integration, null: false, foreign_key: true

      t.string :external_id, null: false

      t.timestamps
    end

    add_index :integration_mappings,
              %i[record_type record_id integration_id],
              name: 'index_integration_mappings_uniqueness',
              unique: true
  end
end
