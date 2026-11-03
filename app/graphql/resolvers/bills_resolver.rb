module Resolvers
  class BillsResolver < CollectionResolver
    MODEL = PaymentTransaction

    argument :filter, Types::BillFilterType, required: false

    type Types::BillCollectionType, null: false
  end
end
