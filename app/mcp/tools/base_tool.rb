module Tools
  class BaseTool < MCP::Tool
    class << self
      attr_reader :field

      def call(server_context:, **arguments)
        context = server_context.slice(:authorizable, :session)

        execute(document(profile_for(context)), context:, variables: variables(arguments))
      end

      def arguments_schema = ArgumentSchema.call(field.arguments.values)
      def description_value = field&.description || super

      def document(profile)
        fields = selection(field.type.unwrap, profile, depth: selection_depth)

        "#{operation_type}(#{variable_definitions}) { #{field.graphql_name}(#{argument_list}) { #{fields} } }"
      end

      def execute(query, context:, variables: {}, operation_name: nil)
        result = TMSSchema.execute(query, context:, operation_name:, variables:).to_h

        MCP::Tool::Response.new([{ text: result.to_json, type: 'text' }], error: result.key?('errors'))
      end

      def operation_type = 'query'
      def profile_for(context) = GraphQL::Query.new(TMSSchema, nil, context:).types
      def root_type = Types::QueryType

      def root_field(name)
        @field = root_type.get_field(name.to_s.camelize(:lower))

        input_schema(arguments_schema)
      end

      def selection(type, profile, depth:)
        profile.fields(type).sort_by(&:graphql_name).filter_map { |type_field| field_selection(type_field, profile, depth:) }.join(' ')
      end

      def selection_depth = 0
      def variables(arguments) = arguments.compact.deep_transform_keys { |key| key.to_s.camelize(:lower) }

      private

      def argument_list = field.arguments.values.map { |argument| "#{argument.graphql_name}: $#{argument.graphql_name}" }.join(', ')

      def field_selection(type_field, profile, depth:)
        return if profile.arguments(type_field).any?

        field_type = type_field.type.unwrap
        return type_field.graphql_name if field_type.kind.leaf?
        return unless field_type.kind.object? && depth.positive?

        selection(field_type, profile, depth: depth - 1).presence&.then { |nested| "#{type_field.graphql_name} { #{nested} }" }
      end

      def variable_definitions
        field.arguments.values.map { |argument| "$#{argument.graphql_name}: #{variable_type(argument)}" }.join(', ')
      end

      def variable_type(argument)
        (argument.default_value? && argument.type.non_null? ? argument.type.of_type : argument.type).to_type_signature
      end
    end
  end
end
