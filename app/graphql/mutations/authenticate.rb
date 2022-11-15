# frozen_string_literal: true

module Mutations
  class Authenticate < BaseMutation
    null true

    argument :credentials, Types::AuthProviderCredentialsInputObject, required: false

    field :token, String, null: true
    field :user, Types::UserType, null: true

    def resolve(credentials: nil)
      return unless credentials

      user = User.find_by_email(credentials[:email])

      return unless user
      return unless user.valid_password?(credentials[:password])

      crypt = ActiveSupport::MessageEncryptor.new(Rails.application.credentials.secret_key_base.byteslice(0..31))
      token = crypt.encrypt_and_sign("user-id:#{user.id}")

      context[:session][:token] = token

      { user:, token: }
    end
  end
end
