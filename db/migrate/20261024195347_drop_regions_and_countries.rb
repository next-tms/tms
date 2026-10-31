class DropRegionsAndCountries < ActiveRecord::Migration[8.1]
  class Address < ActiveRecord::Base; end
  class BrokerCountry < ActiveRecord::Base; end
  class Country < ActiveRecord::Base; end
  class Location < ActiveRecord::Base; end
  class Region < ActiveRecord::Base; end
  class StandardizedAddress < ActiveRecord::Base; end
  class TrackingEvent < ActiveRecord::Base; end

  COUNTRY_MODELS = [Address, BrokerCountry, StandardizedAddress, TrackingEvent].freeze
  REGION_MODELS = [Address, Location, StandardizedAddress, TrackingEvent].freeze

  def up
    drop_table :regions
    drop_table :countries
  end

  def down
    create_table :countries do |t|
      t.string :alpha2_code
      t.string :alpha3_code
      t.string :name
      t.integer :un_code

      t.timestamps
    end

    create_table :regions do |t|
      t.string :abbreviation, null: false, index: true
      t.references :country, foreign_key: true, null: false
      t.string :iso31662, null: false
      t.string :name, null: false, index: true

      t.timestamps
    end

    say 'populate(:countries, :regions)'
    Transponder::ORM::Country.all.to_a.each do |transponder_country|
      country = Country.create!(
        alpha2_code: transponder_country.alpha2,
        alpha3_code: transponder_country.alpha3,
        name: transponder_country.name,
        un_code: transponder_country.numeric
      )

      transponder_country.regions.each do |transponder_region|
        Region.create!(
          abbreviation: transponder_region.abbreviation,
          country_id: country.id,
          iso31662: transponder_region.iso31662.tr('-', '_'),
          name: transponder_region.name
        )
      end
    end

    # Records can keep codes that Transponder no longer returns, so the earlier migrations can still restore their ids
    say 'populate(:countries, :regions) for retired codes'
    region_iso31662s = REGION_MODELS.flat_map { |model| model.distinct.pluck(:region_iso31662) }.compact.uniq
    country_alpha2s = COUNTRY_MODELS.flat_map { |model| model.distinct.pluck(:country_alpha2) }.compact
    country_alpha2s = (country_alpha2s + region_iso31662s.map { |iso31662| iso31662.split('-', 2).first }).uniq

    (country_alpha2s - Country.pluck(:alpha2_code)).each { |alpha2| Country.create!(alpha2_code: alpha2, name: alpha2) }

    (region_iso31662s.map { |iso31662| iso31662.tr('-', '_') } - Region.pluck(:iso31662)).each do |iso31662|
      alpha2, abbreviation = iso31662.split('_', 2)

      Region.create!(abbreviation:, country_id: Country.find_by!(alpha2_code: alpha2).id, iso31662:, name: iso31662.tr('_', '-'))
    end
  end
end
