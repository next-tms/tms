module Types
  class InvoiceCollectionType < Types::CollectionType
    field :items, [Types::InvoiceType], null: false
  end
end
