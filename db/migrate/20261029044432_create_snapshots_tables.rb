class CreateSnapshotsTables < ActiveRecord::Migration[8.1]
  def change
    create_table(:snapshots) do |t|
      t.belongs_to(:item, polymorphic: true, null: false, index: true)
      t.belongs_to(:user, polymorphic: true)
      t.datetime(:created_at, null: false)
      t.string(:identifier, index: true)
      t.jsonb(:metadata)

      t.index(%i[identifier item_id item_type], unique: true)
    end

    create_table(:snapshot_items) do |t|
      t.belongs_to(:snapshot, null: false, index: true)
      t.belongs_to(:item, polymorphic: true, null: false, index: true)
      t.datetime(:created_at, null: false)
      t.jsonb(:object, null: false)
      t.string(:child_group_name)

      t.index(%i[snapshot_id item_id item_type])
    end
  end
end
