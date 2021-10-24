# frozen_string_literal: true

class AddOpenStreetMapResultUpdatedAtToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :open_street_map_result_updated_at, :datetime
  end
end
