# frozen_string_literal: true

class Area < ApplicationRecord
  has_many :location_areas
  has_many :locations, through: :location_areas

  validates_presence_of :name

  def zip_codes
    locations.map(&:zip_code)
  end
end
