module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    def initialize(*, visible_to: nil, **, &)
      @visible_to = visible_to

      super(*, **, &)
    end

    def description(text = nil) = text ? super : Translation.call(:fields, owner.graphql_name.underscore, original_name) || super

    def visible?(context)
      return super if @visible_to.nil?

      super && policy_class.new(nil, authorizable: context[:authorizable]).apply(@visible_to)
    end

    private

    def policy_class = owner.policy_class
  end
end
