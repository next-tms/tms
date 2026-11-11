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
