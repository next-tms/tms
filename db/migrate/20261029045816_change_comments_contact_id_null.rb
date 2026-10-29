class ChangeCommentsContactIdNull < ActiveRecord::Migration[8.1]
  def change = change_column_null(:comments, :contact_id, true)
end
