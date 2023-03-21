# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    include ActionPolicy::GraphQL::Behaviour

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    class << self
      # This is to have multiple related queries in one file rather than to create
      # a file for every query that is touching the same entity e.g Multiple queries
      # for shipment depending on load_id, broker_carrier etc.
      # Ref: https://github.com/rmosolgo/graphql-ruby/blob/c5bb72245b999cbafcf8a90d9572d2375cf60582/lib/graphql/schema/member/has_fields.rb#L72
      def multiple_fields(*args)
        args.each do |klass|
          klass.fields.values.each do |field|
            add_field(field)
          end
        end
      end
    end
  end
end
