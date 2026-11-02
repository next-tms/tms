class AddTimestampsToCustomers < ActiveRecord::Migration[8.1]
  def change = add_timestamps(:customers, default: -> { 'CURRENT_TIMESTAMP' }, null: false)
end
