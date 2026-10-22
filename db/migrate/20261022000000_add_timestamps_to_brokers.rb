class AddTimestampsToBrokers < ActiveRecord::Migration[8.1]
  def change
    add_timestamps :brokers, default: -> { 'CURRENT_TIMESTAMP' }, null: false
  end
end
