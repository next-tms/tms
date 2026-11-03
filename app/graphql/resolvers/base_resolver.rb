module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    include ActionPolicy::GraphQL::Behaviour

    private

    def authorization_context = { authorizable: context[:authorizable] }
  end
end
