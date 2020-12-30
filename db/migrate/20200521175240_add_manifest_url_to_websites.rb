class AddManifestUrlToWebsites < ActiveRecord::Migration[6.0]
  def change
    add_column :websites, :manifest_url, :string
  end
end
