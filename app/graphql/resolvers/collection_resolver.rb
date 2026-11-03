module Resolvers
  class CollectionResolver < BaseResolver
    include Resolvers::Concerns::Filterable
  end
end
