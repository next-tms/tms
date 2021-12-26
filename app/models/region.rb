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
  belongs_to :country

  has_many :addresses

  validates :abbreviation, presence: true
  validates :name, presence: true
end
