class CreatePackagings < ActiveRecord::Migration[5.1]
  def change
    create_table :packagings do |t|
      t.string :name
    end
  end
end
