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
# @!attribute region_id
#   @return []
#
# Indexes
#
#  index_locations_on_region_id  (region_id)
#  index_locations_on_zip_code   (zip_code)
#
# Foreign Keys
#
#  fk_rails_...  (region_id => regions.id)
#
class Location < ApplicationRecord
  belongs_to :region

  has_many :location_areas
  has_many :areas, through: :location_areas
end
