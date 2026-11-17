module Types
  class TaskCollectionType < Types::CollectionType
    field :items, [Types::TaskType], null: false
  end
end
