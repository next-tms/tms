class Types::Iso31661Alpha2Type < Types::BaseEnum
  description 'ISO 3166-1 alpha-2 country code (e.g. US)'

  class << self
    # Inputs must be a current code, but a stored code that Transponder no longer returns is still output as is
    def coerce_result(value, context)
      super
    rescue self::UnresolvedValueError
      value
    end

    def enum_values(_context = nil)
      Grid::ORM::Country.all.map { |country| GraphQL::Schema::EnumValue.new(country.alpha2, owner: self, value: country.alpha2) }
    end
  end
end
