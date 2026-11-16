class Freightview::ApplicationController < ActionController::API
  include ActionPolicy::Controller
  include APIKeyAuthentication
  include ConditionalRequests
  include Localization

  RATE_LIMIT_WINDOW = 1.minute

  attr_reader :api_key

  authorize :authorizable, through: :current_user

  prepend_before_action :authenticate

  delegate :user, to: :api_key, allow_nil: true, prefix: :current

  etag { [api_key&.user, Setting.all] }

  rate_limit to: 300, within: RATE_LIMIT_WINDOW, by: -> { api_key&.token_digest || request.remote_ip }, with: -> { render_rate_limited }

  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from ActionPolicy::Unauthorized, ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ArgumentError, Date::Error, with: :render_bad_request

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

  def render_bad_request(error) = render_error('ValidationError', error.message, status: :bad_request)

  def render_error(name, message, status:, errors: nil)
    render('freightview/errors/show', locals: { errors:, message:, name: }, status:)
  end

  def render_not_found = render_error('NotFoundError', t('freightview.errors.not_found'), status: :not_found)

  def render_parameter_missing(error)
    errors = [{ message: t('freightview.errors.required'), property: error.param }]

    render_error('ValidationError', t('freightview.errors.missing'), errors:, status: :bad_request)
  end

  def render_rate_limited
    response.headers['Retry-After'] = RATE_LIMIT_WINDOW.to_i.to_s
    render_error('RateLimitError', t('freightview.errors.rate_limited'), status: :too_many_requests)
  end

  def render_record_errors(record)
    errors = record.errors.map { |error| { message: error.message, property: error.attribute } }

    render_error('ValidationError', record.errors.full_messages.to_sentence, errors:, status: :bad_request)
  end

  def render_unauthorized(message)
    response.headers['WWW-Authenticate'] = 'Bearer realm="Freightview"'
    render_error('UnauthorizedError', message, status: :unauthorized)
  end
end
