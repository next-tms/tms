class DropDelays < ActiveRecord::Migration[6.0]
  def up
    drop_table :delays
  end
end
