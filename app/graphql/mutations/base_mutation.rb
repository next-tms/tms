module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    include ActionPolicy::GraphQL::Behaviour

    authorize :authorizable, through: :current_user
  end
end
