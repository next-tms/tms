module Types
  class CustomerFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters Customer
  end
end
