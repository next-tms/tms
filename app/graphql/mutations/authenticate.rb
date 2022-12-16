module Mutations
  class Authenticate < BaseMutation
    argument :credentials, Types::AuthProviderCredentialsInputObject, required: false

    field :token, String, null: true
    field :user, Types::UserType, null: true

    def resolve(credentials: nil)
      return unless credentials

      user = User.find_by_email(credentials[:email])

      return unless user
      return unless user.valid_password?(credentials[:password])

      expiration = 8.hours.from_now.getutc.to_i
      payload = { id: user.id, exp: expiration }
      token = ::JwtManagerService.encode(payload: payload).jwt

      { user:, token: }
    end
  end
end
