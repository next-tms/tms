# == Schema Information
#
# Table name: location_areas
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute area_id
#   @return []
# @!attribute location_id
#   @return []
#
# Indexes
#
#  index_location_areas_on_area_id      (area_id)
#  index_location_areas_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (area_id => areas.id)
#  fk_rails_...  (location_id => locations.id)
#
class LocationArea < ApplicationRecord
  belongs_to :area
  belongs_to :location
end
