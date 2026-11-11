# == Schema Information
#
# Table name: areas
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_areas_on_name  (name)
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_areas_on_name  (name)
#
class Area < ApplicationRecord
  class << self
    # A region area holds one location for the whole region (no ZIP code), for pricing rules by region
    def find_or_create_by_region!(region)
      candidates = joins(:locations).where(locations: { region_iso31662: region.iso31662, zip_code: nil }).preload(:locations)

      # An area with more locations also covers other places, so it is not this region's area
      candidates.find { |area| area.locations.size == 1 } ||
        create!(locations: [Location.new(region:)], name: "#{region.name}, #{region.country.alpha2}")
    end
  end

  has_many :location_areas, dependent: :destroy
  has_many :locations, through: :location_areas

  validates :name, presence: true

  def zip_codes
    locations.map(&:zip_code)
  end
end
