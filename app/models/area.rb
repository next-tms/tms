# frozen_string_literal: true

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
class Area < ApplicationRecord
  has_many :location_areas
  has_many :locations, through: :location_areas

  validates_presence_of :name

  def zip_codes
    locations.map(&:zip_code)
  end
end
