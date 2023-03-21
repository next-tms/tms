# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    def initialize(*args, **kwargs, &block)
      argument_name, _type = args

      # Add a default description to argument fields
      kwargs[:description] ||= argument_name.to_s
      super
    end
  end
end
