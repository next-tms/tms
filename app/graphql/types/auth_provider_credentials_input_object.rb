# frozen_string_literal: true

module Types
  class AuthProviderCredentialsInputObject < Types::BaseInputObject
    description 'GraphQL Input Object for Auth Arguments'

    argument :email, String, required: true
    argument :password, String, required: true
  end
end
