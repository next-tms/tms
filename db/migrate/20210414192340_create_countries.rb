class CreateCountries < ActiveRecord::Migration[6.1]
  def up
    create_table :countries do |t|
      t.string :alpha2_code
      t.string :alpha3_code
      t.string :name
      t.integer :un_code

      t.timestamps
    end

    Country.create(
      alpha2_code: 'US',
      alpha3_code: 'USA',
      un_code: 840,
      name: 'United States of America'
    )
  end

  def down
    drop_table :countries
  end
end
