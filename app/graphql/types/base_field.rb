# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    def initialize(*args, **kwargs, &block)
      # Add a default description to field names
      # Sample kwargs => {:owner=>Types::UserType, :null=>false, :name=>:id, :type=>"ID"}
      kwargs[:description] ||= kwargs[:name].to_s

      super
    end
  end
end
