class RemoveHasSeperateWebsiteCredentialsFromCarriers < ActiveRecord::Migration[7.0]
  def change
    remove_column :carriers, :has_seperate_website_credentials, :boolean
  end
end
