class Types::Iso31661Alpha3Type < Types::BaseEnum
  description 'ISO 3166-1 alpha-3 country code (e.g. USA)'

  class << self
    def enum_values(_context = nil)
      Transponder::ORM::Country.all.map { |country| GraphQL::Schema::EnumValue.new(country.alpha3, owner: self, value: country.alpha3) }
    end
  end
end
