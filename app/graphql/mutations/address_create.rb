# frozen_string_literal: true

module Mutations
  class AddressCreate < BaseMutation
    description 'Creates a new address'

    argument :address_input, Types::AddressInputObject, required: true

    field :address, Types::AddressType, null: true

    def resolve(address_input:)
      address_input_h = address_input.to_hash

      except_keys = address_input_h.keys - (Address.column_names.map(&:to_sym) & address_input_h.keys)
      attributes = address_input_h.except(*except_keys)

      address = ::Address.new(attributes)

      region = Region.find_by(iso31662: address_input[:region_iso31662])
      address.region = region
      address.country = region&.country

      raise GraphQL::ExecutionError.new(
        'Error creating address',
        extensions: address.errors.to_hash,
      ) unless address.save

      { address: }
    end
  end
end
