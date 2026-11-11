class Location < ApplicationRecord
  belongs_to_transponder :region, foreign_key: :region_iso31662

  has_many :location_areas, dependent: :destroy
  has_many :areas, through: :location_areas
end
