module Tools
  module FilterSummary
    class << self
      def call(filter_type, profile)
        predicates = profile.arguments(filter_type).filter_map { |argument| predicate(argument) }
        types = predicates.select { |_attribute, suffix, _type| suffix == 'eq' }.to_h { |attribute, _suffix, type| [attribute, type] }
        name = filter_type.graphql_name
        suffixes = predicates.group_by { |attribute, _suffix, _type| types[attribute] }.transform_values { |entries| entries.map(&:second) }

        [
          <<~TEXT.squish,
            input #{name}: keys join an attribute and a predicate, for example #{types.keys.first}_eq.
            "or" takes a list of #{name} objects.
          TEXT
          'Predicates by attribute type:',
          *lines(suffixes),
          'Attributes by type:',
          *lines(types.keys.group_by { |attribute| types[attribute] })
        ].join("\n")
      end

      def predicate(argument)
        name = argument.graphql_name.underscore
        suffix = SUFFIXES.find { |predicate_suffix| name.end_with?("_#{predicate_suffix}") }

        [name.delete_suffix("_#{suffix}"), suffix, argument.type.unwrap.graphql_name] if suffix
      end

      private

      def lines(names_by_type) = names_by_type.sort.map { |type, names| "  #{type}: #{names.uniq.sort.join(', ')}" }
    end

    SUFFIXES = Types::Concerns::Filterable::PREDICATES.values.flat_map(&:keys).map(&:to_s).uniq.sort_by { |suffix| -suffix.length }.freeze
  end
end
