module Resolvers
  class InvoicesResolver < CollectionResolver
    MODEL = Receivable

    argument :filter, Types::InvoiceFilterType, required: false

    type Types::InvoiceCollectionType, null: false
  end
end
