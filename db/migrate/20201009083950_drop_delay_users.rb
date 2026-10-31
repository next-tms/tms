class DropDelayUsers < ActiveRecord::Migration[6.0]
  def up
    drop_table :delay_users
  end
end
