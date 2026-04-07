module Types
  class BaseEnum < GraphQL::Schema::Enum
    class << self
      def values(enum_records)
        # Ref: https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/schema/enum.rb#L46

        kwargs = { owner: self }

        enum_records.each do |value|
          value = enum_value_class.new(value, **kwargs, &nil)
          own_values[value.graphql_name] = value
        end
      end
    end
  end
end
