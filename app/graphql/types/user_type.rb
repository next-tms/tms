module Types
  class UserType < Types::BaseObject
    description 'GraphQL Object for User Model'

    field :email, String, null: false
    field :first_name, String, null: false
    field :id, ID, null: false
    field :last_name, String, null: false
  end
end
