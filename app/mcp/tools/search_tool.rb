module Tools
  class SearchTool < BaseTool
    class << self
      def arguments_schema
        ArgumentSchema.call(field.arguments.values.reject { |argument| argument.graphql_name == 'filter' }).deep_merge(PROPERTIES)
      end

      def inherited(subclass)
        super
        subclass.annotations(destructive_hint: false, idempotent_hint: true, open_world_hint: false, read_only_hint: true)
      end

      def selection_depth = 1
    end

    PROPERTIES = {
      properties: {
        filter: {
          description: <<~TEXT.squish,
            Ransack predicates keyed by attribute and predicate, for example {"load_id_eq": 1234} or {"or": [{...}, {...}]}.
            Call graphql_schema for every filter field.
          TEXT
          type: 'object'
        },
        page: { minimum: 1 },
        page_size: { maximum: Resolvers::Concerns::Filterable::MAX_PAGE_SIZE, minimum: 1 },
        sort: { description: 'Attributes to sort by, each with an optional direction, for example ["created_at:desc"]' }
      }
    }.freeze
  end
end
