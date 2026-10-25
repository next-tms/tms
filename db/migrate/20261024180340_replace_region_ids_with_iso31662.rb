class ReplaceRegionIdsWithIso31662 < ActiveRecord::Migration[8.1]
  class Address < ActiveRecord::Base; end
  class Location < ActiveRecord::Base; end
  class Region < ActiveRecord::Base; end
  class StandardizedAddress < ActiveRecord::Base; end
  class TrackingEvent < ActiveRecord::Base; end

  MODELS = [ Address, Location, StandardizedAddress, TrackingEvent ].freeze

  def up
    MODELS.each { |model| add_column model.table_name, :region_iso31662, :string }

    MODELS.each(&:reset_column_information)

    say 'populate(:region_iso31662)'
    Region.find_each do |region|
      MODELS.each { |model| model.where(region_id: region.id).update_all(region_iso31662: region.iso31662.tr('_', '-')) }
    end

    change_column_null :locations, :region_iso31662, false
    change_column_null :standardized_addresses, :region_iso31662, false

    MODELS.each do |model|
      add_index model.table_name, :region_iso31662
      remove_reference model.table_name, :region, foreign_key: true, index: true
    end
  end

  def down
    MODELS.each { |model| add_reference model.table_name, :region, foreign_key: true, index: true }

    MODELS.each(&:reset_column_information)

    say 'populate(:region_id)'
    Region.find_each do |region|
      MODELS.each { |model| model.where(region_iso31662: region.iso31662.tr('_', '-')).update_all(region_id: region.id) }
    end

    change_column_null :locations, :region_id, false
    change_column_null :standardized_addresses, :region_id, false

    MODELS.each { |model| remove_column model.table_name, :region_iso31662 }
  end
end
