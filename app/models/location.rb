# frozen_string_literal: true

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
#
# Indexes
#
#  index_locations_on_zip_code  (zip_code)
#
class Location < ApplicationRecord
  has_many :location_areas
  has_many :areas, through: :location_areas
end
