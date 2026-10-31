class ReplaceCountryIdsWithAlpha2 < ActiveRecord::Migration[8.1]
  class Address < ActiveRecord::Base; end
  class BrokerCountry < ActiveRecord::Base; end
  class Country < ActiveRecord::Base; end
  class StandardizedAddress < ActiveRecord::Base; end
  class TrackingEvent < ActiveRecord::Base; end

  MODELS = [Address, BrokerCountry, StandardizedAddress, TrackingEvent].freeze

  def up
    # tracking_events.country_alpha2 already exists (unused since country_id replaced it)
    add_column :addresses, :country_alpha2, :string, limit: 2
    add_column :broker_countries, :country_alpha2, :string, limit: 2
    add_column :standardized_addresses, :country_alpha2, :string, limit: 2

    MODELS.each(&:reset_column_information)

    say 'populate(:country_alpha2)'
    Country.find_each do |country|
      MODELS.each { |model| model.where(country_id: country.id).update_all(country_alpha2: country.alpha2_code) }
    end

    change_column_null :addresses, :country_alpha2, false
    change_column_null :broker_countries, :country_alpha2, false
    change_column_null :standardized_addresses, :country_alpha2, false

    MODELS.each do |model|
      add_index model.table_name, :country_alpha2
      remove_reference model.table_name, :country, foreign_key: true, index: true
    end
  end

  def down
    MODELS.each { |model| add_reference model.table_name, :country, foreign_key: true, index: true }

    MODELS.each(&:reset_column_information)

    say 'populate(:country_id)'
    Country.find_each do |country|
      MODELS.each { |model| model.where(country_alpha2: country.alpha2_code).update_all(country_id: country.id) }
    end

    change_column_null :addresses, :country_id, false
    change_column_null :broker_countries, :country_id, false
    change_column_null :standardized_addresses, :country_id, false

    MODELS.each { |model| remove_index model.table_name, :country_alpha2 }

    remove_column :addresses, :country_alpha2
    remove_column :broker_countries, :country_alpha2
    remove_column :standardized_addresses, :country_alpha2
  end
end
