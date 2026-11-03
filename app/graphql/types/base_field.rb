module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    def initialize(*, visible_to: nil, **kwargs, &)
      # Add a default description to field names
      # Sample kwargs => {:owner=>Types::UserType, :null=>false, :name=>:id, :type=>"ID"}
      kwargs[:description] ||= kwargs[:name].to_s
      @visible_to = visible_to

      super(*, **kwargs, &)
    end

    def visible?(context)
      return super if @visible_to.nil?

      super && policy_class.new(nil, authorizable: context[:authorizable]).apply(@visible_to)
    end

    private

    def policy_class = "#{owner.graphql_name}Policy".constantize
  end
end
