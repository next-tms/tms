module Tools
  module ArgumentSchema
    class << self
      def call(arguments)
        {
          properties: arguments.to_h { |argument| [property_name(argument), property(argument)] },
          required: arguments.select { |argument| required?(argument) }.map { |argument| property_name(argument) },
          type: 'object'
        }
      end

      def property(argument) = { description: argument.description, **type(argument.type) }.compact
      def property_name(argument) = argument.graphql_name.underscore.to_sym

      def type(graphql_type)
        return type(graphql_type.of_type) if graphql_type.non_null?
        return { items: type(graphql_type.of_type), type: 'array' } if graphql_type.list?
        return call(graphql_type.arguments.values) if graphql_type.kind.input_object?
        return enum(graphql_type) if graphql_type.kind.enum?

        SCALARS.fetch(graphql_type.graphql_name, { type: 'string' })
      end

      private

      def enum(enum_type)
        names = enum_type.all_enum_value_definitions.map(&:graphql_name).uniq.sort

        names.empty? ? { description: enum_type.description, type: 'string' } : { enum: names, type: 'string' }
      end

      def required?(argument) = argument.type.non_null? && !argument.default_value?
    end

    SCALARS = {
      'Boolean' => { type: 'boolean' },
      'Float' => { type: 'number' },
      'ISO8601Date' => { format: 'date', type: 'string' },
      'ISO8601DateTime' => { format: 'date-time', type: 'string' },
      'Int' => { type: 'integer' }
    }.freeze
  end
end
