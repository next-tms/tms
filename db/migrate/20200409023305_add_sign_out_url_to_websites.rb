class AddSignOutUrlToWebsites < ActiveRecord::Migration[6.0]
  def change
    add_column :websites, :sign_out_url, :string
  end
end
