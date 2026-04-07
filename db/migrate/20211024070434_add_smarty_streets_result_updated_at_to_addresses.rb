class AddSmartyStreetsResultUpdatedAtToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :smarty_streets_result_updated_at, :datetime
  end
end
