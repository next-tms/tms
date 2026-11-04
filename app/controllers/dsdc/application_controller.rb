class DSDC::ApplicationController < ActionController::API
  include ActionPolicy::Controller
  include APIKeyAuthentication
  include ConditionalRequests

  RATE_LIMIT_WINDOW = 1.minute

  attr_reader :api_key

  authorize :authorizable, through: :current_user

  before_action :authenticate

  delegate :user, to: :api_key, allow_nil: true, prefix: :current

  etag { [api_key&.user, Setting.all] }

  helper EnumI18nHelper

  rate_limit to: 300, within: RATE_LIMIT_WINDOW, by: -> { api_key&.token_digest || request.remote_ip }, with: -> { render_rate_limited }

  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionPolicy::Unauthorized, ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def authenticate
    @api_key = APIKey.authenticate(request_token)
    message = api_key_error(api_key)

    if message.present?
      render_unauthorized(message)
      return
    end

    api_key.use!
  end

  def render_bad_request(error) = render_error(error.message, status: :bad_request)
  def render_error(message, status:) = render('dsdc/errors/show', locals: { message: }, status:)
  def render_not_found = head(:not_found)

  def render_rate_limited
    response.headers['Retry-After'] = RATE_LIMIT_WINDOW.to_i.to_s
    render_error(t('dsdc.errors.rate_limited'), status: :too_many_requests)
  end

  def render_unauthorized(message)
    response.headers['WWW-Authenticate'] = 'Bearer realm="DSDC"'
    render_error(message, status: :unauthorized)
  end
end
