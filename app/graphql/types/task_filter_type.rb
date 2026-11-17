module Types
  class TaskFilterType < Types::BaseInputObject
    include Types::Concerns::Filterable

    filters Problem
  end
end
