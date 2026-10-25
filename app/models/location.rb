# == Schema Information
#
# Table name: locations
#
# @!attribute id
#   @return []
# @!attribute zip_code
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute region_iso31662
#   @return [String]
#
# Indexes
#
#  index_locations_on_region_iso31662  (region_iso31662)
#  index_locations_on_zip_code         (zip_code)
#
class Location < ApplicationRecord
  belongs_to_transponder :region, foreign_key: :region_iso31662

  has_many :location_areas
  has_many :areas, through: :location_areas
end
