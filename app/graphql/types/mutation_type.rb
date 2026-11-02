module Types
  class MutationType < Types::BaseObject
    description 'GraphQL Mutations'

    field :address_create, mutation: Mutations::AddressCreate
    field :fetch_rates, mutation: Mutations::FetchRates
  end
end
