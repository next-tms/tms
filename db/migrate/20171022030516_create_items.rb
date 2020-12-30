class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.integer :l
      t.integer :w
      t.integer :h
      t.integer :nmfc
      t.integer :freight_class
      t.boolean :hazmat
      t.boolean :refrigerated
      t.string :desc
      t.integer :packaging_id, foreign_key: { to_table: :packagings }
    end
  end
end
