module Types
  class BillFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters PaymentTransaction
  end
end
