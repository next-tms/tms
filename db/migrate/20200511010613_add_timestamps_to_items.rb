class AddTimestampsToItems < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :items, null: true

    long_ago = DateTime.new(2000, 1, 1)
    Item.update_all(created_at: long_ago, updated_at: long_ago)

    change_column_null :items, :created_at, false
    change_column_null :items, :updated_at, false
  end
end
