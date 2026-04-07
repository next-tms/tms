class LiftoffSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  max_complexity 200
  max_depth 10

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # GraphQL-Ruby calls this when something goes wrong while running a query:

  rescue_from ActiveRecord::RecordNotFound do |exception|
    GraphQL::ExecutionError.new("#{exception.model} not found")
  end

  class << self
    # Union and Interface Resolution
    # TODO: Implement this method to return the correct GraphQL object type for `obj`
    def resolve_type(abstract_type, obj, ctx) = raise(GraphQL::RequiredImplementationMissingError)

    # Relay-style Object Identification:

    # Return a string UUID for `object`
    def id_from_object(object, type_definition, query_ctx) = object.to_gid_param

    # Given a string UUID, find the object
    def object_from_id(global_id, query_ctx) = GlobalID.find(global_id)
  end
end
