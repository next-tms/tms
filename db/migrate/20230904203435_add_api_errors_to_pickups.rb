class AddAPIErrorsToPickups < ActiveRecord::Migration[7.0]
  def change
    add_column(:pickups, :api_errors, :jsonb, default: '[]', null: false)
    add_index :pickups, :api_errors
  end
end
