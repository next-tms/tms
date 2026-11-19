class Types::Iso31662Type < Types::BaseEnum
  description 'ISO 3166-2 code with an underscore between each division (e.g. US_CA for US-CA)'

  NAME_PATTERN = /\A[_A-Za-z][_A-Za-z0-9]*\z/

  class << self
    # GraphQL enum names cannot contain hyphens, and some codes (e.g. LR-X1~) are not valid names at all
    def enum_values(_context = nil)
      Grid::ORM::Region.all.filter_map do |region|
        name = region.iso31662.tr('-', '_')
        next unless name.match?(NAME_PATTERN)

        GraphQL::Schema::EnumValue.new(name, owner: self, value: region.iso31662)
      end
    end
  end
end
