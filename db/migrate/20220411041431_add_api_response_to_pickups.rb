class AddAPIResponseToPickups < ActiveRecord::Migration[7.0]
  def change
    add_column :pickups, :api_response, :text
  end
end
