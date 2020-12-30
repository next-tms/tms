class DropDelays < ActiveRecord::Migration[6.0]
  def change
    drop_table :delays
  end
end
