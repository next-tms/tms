module Types
  class MutationType < Types::BaseObject
    description 'GraphQL Mutations'

    field :address_create, mutation: Mutations::AddressCreate
    field :fetch_rates, mutation: Mutations::FetchRates
    field :quote_create, mutation: Mutations::QuoteCreate
    field :shipment_create, mutation: Mutations::ShipmentCreate
  end
end
