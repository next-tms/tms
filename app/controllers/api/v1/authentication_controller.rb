# frozen_string_literal: true

class Api::V1::AuthenticationController < Api::ApplicationController
  skip_before_action :authenticate_request

  def authenticate
    command = AuthenticateUser.call(params[:email], params[:password])

    if command.success?
      render json: { auth_token: command.result, auth_token_expires: 24.hours.from_now.as_json }
    else
      render json: { error: command.errors }, status: :unauthorized
    end
  end
end
