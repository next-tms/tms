class AddSloganToWebsites < ActiveRecord::Migration[5.2]
  def change
    add_column :websites, :slogan, :string
  end
end
