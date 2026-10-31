class AddUniqueIndexesForUniquenessValidations < ActiveRecord::Migration[8.1]
  def change
    add_index :accessorials, :name, unique: true
    add_index :carriers, :mc_number, unique: true
    add_index :packagings, :name, unique: true

    remove_index :broker_countries, :country_alpha2
    add_index :broker_countries, :country_alpha2, unique: true

    remove_index :customers, :name
    add_index :customers, :name, unique: true

    remove_index :settings, :key
    add_index :settings, :key, unique: true
  end
end
