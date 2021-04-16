class AddCountryToAddress < ActiveRecord::Migration[6.1]
  def up
    add_reference :addresses, :country, null: true, foreign_key: true

    Address.where(country: nil).update_all(
      country_id: Country.find_by_alpha2_code('US').id
    )

    change_column :addresses, :country_id, :integer, null: false
  end

  def down
    remove_column :addresses, :country_id, :integer
  end
end
