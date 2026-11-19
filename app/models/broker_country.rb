class BrokerCountry < ApplicationRecord
  class << self
    def countries = Grid::ORM::Country.where(alpha2: pluck(:country_alpha2))
  end

  belongs_to_orm :country, class_name: 'Grid::ORM::Country', foreign_key: :country_alpha2

  validates :country_alpha2, uniqueness: true
end
