class AddModalUrlToWebsites < ActiveRecord::Migration[6.0]
  def change
    add_column :websites, :modal_url, :string
  end
end
