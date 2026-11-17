module Tools
  class GraphQLSchema < BaseTool
    tool_name 'graphql_schema'
    description <<~TEXT.squish
      Get the GraphQL schema of the TMS API, limited to the types and fields your role can use.
      Without type_name, it returns the Query and Mutation types in SDL and the names of every other type.
    TEXT
    annotations(destructive_hint: false, idempotent_hint: true, open_world_hint: false, read_only_hint: true)
    input_schema(properties: {
                   type_name: {
                     description: 'Name of one type to describe, for example Shipment or ShipmentFilter',
                     type: 'string'
                   }
                 })

    class << self
      def call(server_context:, type_name: nil)
        context = server_context.slice(:authorizable, :session)
        profile = profile_for(context)
        printer = GraphQL::Schema::Printer.new(LiftoffSchema, context:)
        type = profile.type(type_name) if type_name

        return MCP::Tool::Response.new([{ text: "Unknown type: #{type_name}", type: 'text' }], error: true) if type_name && type.nil?

        MCP::Tool::Response.new([{ text: type ? describe(type, profile, printer) : overview(profile, printer), type: 'text' }])
      end

      def describe(type, profile, printer)
        type.include?(Types::Concerns::Filterable) ? FilterSummary.call(type, profile) : printer.print_type(type)
      end

      def overview(profile, printer)
        names = profile.all_types.map(&:graphql_name).reject { |name| name.start_with?('__') }.sort

        [printer.print_type(profile.query_root), printer.print_type(profile.mutation_root), "Types: #{names.join(', ')}"].join("\n\n")
      end
    end
  end
end
