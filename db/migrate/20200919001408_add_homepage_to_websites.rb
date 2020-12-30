class AddHomepageToWebsites < ActiveRecord::Migration[6.0]
  def change
    add_column :websites, :homepage, :string, null: true
  end
end
