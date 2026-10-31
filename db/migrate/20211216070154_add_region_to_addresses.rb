class AddRegionToAddresses < ActiveRecord::Migration[6.1]
  def up
    add_reference :addresses, :region, null: true, foreign_key: true

    say 'Populate addresses.region_id'
    Region.includes(:country).find_each do |region|
      Address
        .where('TRIM(state) ILIKE ?', region.abbreviation)
        .update_all(country_id: region.country.id, region_id: region.id, state: nil)
    end

    usa = Country.find_by(alpha2_code: 'US')
    Address.where(region: nil).where(city: '83401').update_all(region_id: usa.regions.find_by(abbreviation: 'ID').id)
    Address.where(region: nil).where(zip_code: '01824').update_all(region_id: usa.regions.find_by(abbreviation: 'MA').id)
    Address.where(region: nil).where(zip_code: '03031').update_all(region_id: usa.regions.find_by(abbreviation: 'NH').id)
    Address.where(region: nil).where(zip_code: '08402').update_all(region_id: usa.regions.find_by(abbreviation: 'NJ').id)
    Address.where(region: nil).where(zip_code: '21663').update_all(region_id: usa.regions.find_by(abbreviation: 'MD').id)
    Address.where(region: nil).where(zip_code: '28768').update_all(region_id: usa.regions.find_by(abbreviation: 'NC').id)
    Address.where(region: nil).where(zip_code: '29072').update_all(region_id: usa.regions.find_by(abbreviation: 'SC').id)
    Address.where(region: nil).where(zip_code: '33133').update_all(region_id: usa.regions.find_by(abbreviation: 'FL').id)
    Address.where(region: nil).where(zip_code: '33172').update_all(region_id: usa.regions.find_by(abbreviation: 'KS').id)
    Address.where(region: nil).where(zip_code: '33195').update_all(region_id: usa.regions.find_by(abbreviation: 'FL').id)
    Address.where(region: nil).where(zip_code: '33908').update_all(region_id: usa.regions.find_by(abbreviation: 'FL').id)
    Address.where(region: nil).where(zip_code: '35209').update_all(region_id: usa.regions.find_by(abbreviation: 'AL').id)
    Address.where(region: nil).where(zip_code: '35611').update_all(region_id: usa.regions.find_by(abbreviation: 'AL').id)
    Address.where(region: nil).where(zip_code: '37501').update_all(region_id: usa.regions.find_by(abbreviation: 'FL').id)
    Address.where(region: nil).where(zip_code: '38108').update_all(region_id: usa.regions.find_by(abbreviation: 'TN').id)
    Address.where(region: nil).where(zip_code: '45409').update_all(region_id: usa.regions.find_by(abbreviation: 'OH').id)
    Address.where(region: nil).where(zip_code: '45672').update_all(region_id: usa.regions.find_by(abbreviation: 'OH').id)
    Address.where(region: nil).where(zip_code: '46268').update_all(region_id: usa.regions.find_by(abbreviation: 'IN').id)
    Address.where(region: nil).where(zip_code: '46514').update_all(region_id: usa.regions.find_by(abbreviation: 'IN').id)
    Address.where(region: nil).where(zip_code: '67880').update_all(region_id: usa.regions.find_by(abbreviation: 'KS').id)
    Address.where(region: nil).where(zip_code: '77055').update_all(region_id: usa.regions.find_by(abbreviation: 'TX').id)
    Address.where(region: nil).where(zip_code: '90046').update_all(region_id: usa.regions.find_by(abbreviation: 'CA').id)
    Address.where(region: nil).where(zip_code: '90249').update_all(region_id: usa.regions.find_by(abbreviation: 'CA').id)
    Address.where(region: nil).where(zip_code: '92064').update_all(region_id: usa.regions.find_by(abbreviation: 'CA').id)
    Address.where(region: nil).where(zip_code: '92408').update_all(region_id: usa.regions.find_by(abbreviation: 'CA').id)
    Address.where(region: nil).where(zip_code: '94519').update_all(region_id: usa.regions.find_by(abbreviation: 'CA').id)
    Address.where(region: nil).where(zip_code: '94590').update_all(region_id: usa.regions.find_by(abbreviation: 'CA').id)

    Address.update_all(state: nil)

    change_column_null :addresses, :region_id, :false
  end

  def down
    say 'Populate addresses.state'
    Region.includes(:country).find_each do |region|
      Address.where(country: region.country, region:).update_all(state: region.abbreviation)
    end

    remove_column :addresses, :region_id
  end
end
