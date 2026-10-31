class AddTimestampsToCarriers < ActiveRecord::Migration[8.1]
  def change
    add_timestamps :carriers, default: -> { 'CURRENT_TIMESTAMP' }, null: false
  end
end
