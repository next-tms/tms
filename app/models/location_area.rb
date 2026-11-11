class LocationArea < ApplicationRecord
  belongs_to :area
  belongs_to :location
end
