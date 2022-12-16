module Types
  class AuthProviderCredentialsInputObject < Types::BaseInputObject
    argument :email, String, required: true
    argument :password, String, required: true
  end
end
