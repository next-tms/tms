class CreateWebsites < ActiveRecord::Migration[5.1]
  def change
    create_table :websites do |t|
      t.references :broker, foreign_key: true
      t.string :domain, required: true
      t.string :copyright_holder, required: true
      t.text :logo_image_data
      t.text :css
    end
  end
end
