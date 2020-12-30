class AddDescToWebsites < ActiveRecord::Migration[5.2]
  def change
    add_column :websites, :desc, :text
  end
end
