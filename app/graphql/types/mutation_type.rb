# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :authenticate, mutation: Mutations::Authenticate

    field :address_create, mutation: Mutations::AddressCreate
  end
end
