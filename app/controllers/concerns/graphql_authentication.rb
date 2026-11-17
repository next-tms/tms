module GraphQLAuthentication
  extend ActiveSupport::Concern

  include ActionController::RequestForgeryProtection
  include APIKeyAuthentication

  included do
    attr_reader :api_key, :authorizable

    self.allow_forgery_protection = ActionController::Base.allow_forgery_protection

    prepend_before_action :authenticate!
  end

  def authenticate! = request_token.present? ? authenticate_api_key : authenticate_session

  def authenticate_api_key
    @api_key = APIKey.authenticate(request_token)
    message = api_key_error(api_key)

    if message.present?
      render_unauthorized_error_response(message)
      return
    end

    @authorizable = api_key.user
    @current_user = api_key.user
    api_key.use!
  end

  def authenticate_session
    user = catch(:warden) { warden.user(:user) } if verified_request?

    unless user.is_a?(User)
      render_unauthorized_error_response('Not Authorized')
      return
    end

    @authorizable = user
    @current_user = user
  end

  def render_unauthorized_error_response(error) = render('application/error', locals: { error: }, status: :unauthorized)
end
