module Types
  module Concerns
    module Filterable
      extend ActiveSupport::Concern

      class_methods do
        def add_attribute_arguments(predicate, type)
          PREDICATES.fetch(type, {}).each do |suffix, argument_type|
            name = "#{predicate}_#{suffix}"

            argument(name, argument_type, required: false) unless own_arguments.key?(name.camelize(:lower))
          end
        end

        def add_model_arguments(model, prefix = nil, visited_models = Set[model], depth = 0)
          model.ransackable_attributes.each do |attribute_name|
            add_attribute_arguments([prefix, attribute_name].compact.join('_'), attribute_type(model, attribute_name))
          end

          return if depth >= MAX_DEPTH

          ransackable_reflections(model).each do |reflection|
            next if visited_models.include?(reflection.klass)

            association_prefix = [prefix, reflection.name].compact.join('_')

            add_model_arguments(reflection.klass, association_prefix, visited_models | [reflection.klass], depth + 1)
          end
        end

        def attribute_type(model, attribute_name)
          return :string if model._ransackers.key?(attribute_name)

          model.columns_hash[attribute_name]&.type
        end

        def filters(model)
          argument(:or, [self], required: false)

          add_model_arguments(model)
        end

        def ransackable_reflections(model)
          model.reflect_on_all_associations.select do |reflection|
            !reflection.polymorphic? && !reflection.through_reflection? && model.ransackable_associations.include?(reflection.name.to_s)
          end
        end
      end

      MAX_DEPTH = 3

      PREDICATES = {
        boolean: { eq: GraphQL::Types::Boolean, not_eq: GraphQL::Types::Boolean, null: GraphQL::Types::Boolean },
        date: {
          eq: GraphQL::Types::ISO8601Date,
          gt: GraphQL::Types::ISO8601Date,
          gteq: GraphQL::Types::ISO8601Date,
          lt: GraphQL::Types::ISO8601Date,
          lteq: GraphQL::Types::ISO8601Date,
          not_eq: GraphQL::Types::ISO8601Date,
          null: GraphQL::Types::Boolean
        },
        datetime: {
          eq: GraphQL::Types::ISO8601DateTime,
          gt: GraphQL::Types::ISO8601DateTime,
          gteq: GraphQL::Types::ISO8601DateTime,
          lt: GraphQL::Types::ISO8601DateTime,
          lteq: GraphQL::Types::ISO8601DateTime,
          not_eq: GraphQL::Types::ISO8601DateTime,
          null: GraphQL::Types::Boolean
        },
        integer: {
          eq: GraphQL::Types::Int,
          gt: GraphQL::Types::Int,
          gteq: GraphQL::Types::Int,
          in: [GraphQL::Types::Int],
          lt: GraphQL::Types::Int,
          lteq: GraphQL::Types::Int,
          not_eq: GraphQL::Types::Int,
          not_in: [GraphQL::Types::Int],
          null: GraphQL::Types::Boolean
        },
        string: {
          cont: GraphQL::Types::String,
          end: GraphQL::Types::String,
          eq: GraphQL::Types::String,
          in: [GraphQL::Types::String],
          not_cont: GraphQL::Types::String,
          not_end: GraphQL::Types::String,
          not_eq: GraphQL::Types::String,
          not_in: [GraphQL::Types::String],
          not_start: GraphQL::Types::String,
          null: GraphQL::Types::Boolean,
          start: GraphQL::Types::String
        }
      }.tap { |predicates| predicates[:text] = predicates[:string] }.freeze
    end
  end
end
