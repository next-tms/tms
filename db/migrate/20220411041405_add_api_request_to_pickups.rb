class AddAPIRequestToPickups < ActiveRecord::Migration[7.0]
  def change
    add_column :pickups, :api_request, :text
  end
end
