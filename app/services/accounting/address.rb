module Accounting
  class Address
    include ActiveModel::Model

    attr_accessor :city, :country, :line1, :line2, :postal_code, :region

    def country_alpha2 = Grid::ORM::Country.find_by(name: country)&.alpha2

    def to_address(default_country_alpha2)
      alpha2 = country_alpha2 || default_country_alpha2

      ::Address.new(
        city:,
        country_alpha2: alpha2,
        region_iso31662: ("#{alpha2}-#{region.upcase}" if region.present?),
        street: line1,
        street2: line2,
        zip_code: postal_code
      )
    end
  end
end
