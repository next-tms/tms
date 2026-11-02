class AddTimestampsToBrokerAccessorial < ActiveRecord::Migration[8.1]
  def change = add_timestamps(:broker_accessorials, default: -> { 'CURRENT_TIMESTAMP' }, null: false)
end
