# frozen_string_literal: true

class Types::Iso31662Type < Types::BaseEnum
  description 'ISO 3166-2 code with hyphens between each division (e.g. US_CA)'

  class << self
    def enum_values(context)
      values = []
      Region.find_each { |region| values << region.iso31662 }

      values.map { |value| GraphQL::Schema::EnumValue.new(value, owner: self, value:) }
    end
  end
end
