class BrokerCountry < ApplicationRecord
  class << self
    def countries = Transponder::ORM::Country.where(alpha2: pluck(:country_alpha2))
  end

  belongs_to_transponder :country, foreign_key: :country_alpha2

  validates :country_alpha2, uniqueness: true
end
