module Resolvers
  class TasksResolver < CollectionResolver
    MODEL = Problem

    argument :filter, Types::TaskFilterType, required: false

    type Types::TaskCollectionType, null: false
  end
end
