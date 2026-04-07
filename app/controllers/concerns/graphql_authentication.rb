# frozen_string_literal: true

module GraphQLAuthentication
  extend ActiveSupport::Concern

  InvalidCredentials = Class.new(StandardError)

  included do
    before_action :authenticate!
  end

  def authenticate!
    return if params[:operationName] == 'IntrospectionQuery'
    return if params[:query].include?('authenticate')

    @jwt_error, @current_user = decode_jwt(token: request.headers['Authorization'])

    render_unauthorized_error_response(@jwt_error) and return if @jwt_error
    render_unauthorized_error_response('Not Authorized') and return unless @current_user
  end

  def decode_jwt(token:)
    return [] unless token =~ /Bearer (.+)/

    jwt = Regexp.last_match(1)
    decoded_jwt = ::JwtManagerService.decode(jwt:)
    jwt_error = decoded_jwt.error_message
    id = decoded_jwt.payload&.fetch('id', nil)
    user = User.find_by(id:)

    [ jwt_error, user ]
  end

  def render_unauthorized_error_response(error)
    render(json: { error: }, status: :unauthorized)
  end
end
