module Types
  class InvoiceFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters Receivable
  end
end
