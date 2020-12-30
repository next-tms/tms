class DropDelayUsers < ActiveRecord::Migration[6.0]
  def change
    drop_table :delay_users
  end
end
