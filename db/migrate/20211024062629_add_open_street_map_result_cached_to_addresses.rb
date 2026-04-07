class AddOpenStreetMapResultCachedToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :open_street_map_result_cached, :text
  end
end
