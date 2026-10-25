# == Schema Information
#
# Table name: broker_countries
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_alpha2
#   @return [String]
#
# Indexes
#
#  index_broker_countries_on_country_alpha2  (country_alpha2)
#
class BrokerCountry < ApplicationRecord
  class << self
    def countries = Transponder::ORM::Country.where(alpha2: pluck(:country_alpha2))
  end

  after_create_commit :create_region_areas

  belongs_to_transponder :country, foreign_key: :country_alpha2

  validates :country_alpha2, uniqueness: true

  private

  def create_region_areas = country.regions.each { |region| Area.find_or_create_by_region!(region) }
end
