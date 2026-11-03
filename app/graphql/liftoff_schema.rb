class LiftoffSchema < GraphQL::Schema
  class << self
    # Union and Interface Resolution
    # TODO: Implement this method to return the correct GraphQL object type for `obj`
    def resolve_type(_abstract_type, _obj, _ctx) = raise(GraphQL::RequiredImplementationMissingError)

    # Relay-style Object Identification:

    # Return a string UUID for `object`
    def id_from_object(object, _type_definition, _query_ctx) = object.to_gid_param

    # Given a string UUID, find the object
    def object_from_id(global_id, _query_ctx) = GlobalID.find(global_id)
  end

  mutation(Types::MutationType)
  query(Types::QueryType)

  max_complexity 10_000
  max_depth 10

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # GraphQL-Ruby calls this when something goes wrong while running a query:

  rescue_from(ActionPolicy::Unauthorized) do |exception|
    GraphQL::ExecutionError.new(exception.result.message, extensions: { code: 'UNAUTHORIZED' })
  end

  rescue_from(ActiveRecord::RecordNotFound) { |exception| GraphQL::ExecutionError.new("#{exception.model} not found") }

  rescue_from(Pagy::OverflowError) do |exception|
    message = "Page #{exception.pagy.page} is past the last page (#{exception.pagy.last})"

    GraphQL::ExecutionError.new(message, extensions: { code: 'PAGE_OVERFLOW' })
  end

  rescue_from(Ransack::InvalidSearchError) do |exception|
    GraphQL::ExecutionError.new(exception.message, extensions: { code: 'INVALID_FILTER' })
  end
end
