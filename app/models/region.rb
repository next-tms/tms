# frozen_string_literal: true

# == Schema Information
#
# Table name: regions
#
# @!attribute id
#   @return []
# @!attribute abbreviation
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return []
#
# Indexes
#
#  index_regions_on_abbreviation  (abbreviation)
#  index_regions_on_country_id    (country_id)
#  index_regions_on_name          (name)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
class Region < ApplicationRecord
  after_save :create_area

  belongs_to :country

  has_many :addresses
  has_many :areas
  has_many :locations

  validates :abbreviation, presence: true
  validates :name, presence: true

  private

  def create_area
    area = Area.new(name: "#{name}, #{country.alpha2_code}")
    area.locations.build(region: self)
    area.save!
  end
end
