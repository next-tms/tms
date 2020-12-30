class AddFooterUrlToWebsites < ActiveRecord::Migration[6.0]
  def change
    add_column :websites, :footer_url, :string
  end
end
