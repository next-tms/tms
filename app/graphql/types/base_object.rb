module Types
  class BaseObject < GraphQL::Schema::Object
    class << self
      def policy_class = "#{graphql_name}Policy".constantize
    end

    include ActionPolicy::GraphQL::Behaviour

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    private

    def authorization_context = { authorizable: context[:authorizable] }
  end
end
