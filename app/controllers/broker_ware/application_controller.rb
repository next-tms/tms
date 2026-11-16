class BrokerWare::ApplicationController < ActionController::API
  include AbstractController::Translation
  include ActionPolicy::Controller
  include ConditionalRequests

  RATE_LIMIT_WINDOW = 1.minute

  attr_reader :api_key

  authorize :authorizable, through: :current_user

  before_action :underscore_params
  before_action :authenticate

  delegate :user, to: :api_key, allow_nil: true, prefix: :current

  etag { [api_key&.user, Setting.all] }

  helper EnumI18nHelper

  rate_limit to: 300, within: RATE_LIMIT_WINDOW, by: -> { api_key&.token_digest || request.remote_ip }, with: -> { render_rate_limited }

  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionPolicy::Unauthorized, ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def authenticate
    @api_key = APIKey.find_signed(request_token, purpose: :access_token) if request_token

    unless usable_api_key?
      render_unauthorized
      return
    end

    api_key.use!
  end

  def broker_customer = current_user.companyable
  def render_bad_request(error) = render_error(error.message, status: :bad_request)
  def render_error(message, status:) = render('broker_ware/errors/show', locals: { message: }, status:)
  def render_not_found = head(:not_found)

  def render_rate_limited
    response.headers['Retry-After'] = RATE_LIMIT_WINDOW.to_i.to_s
    render_error(t('broker_ware.errors.rate_limited'), status: :too_many_requests)
  end

  def render_unauthorized
    response.headers['WWW-Authenticate'] = 'Bearer realm="BrokerWare"'
    render_error(t('broker_ware.errors.unauthorized'), status: :unauthorized)
  end

  def require_param(values, key) = values.fetch(key) { raise(ActionController::ParameterMissing, BrokerWare.camelize(key)) }
  def request_token = ActionController::HttpAuthentication::Token.token_and_options(request)&.first
  def underscore_params = params.deep_transform_keys!(&:underscore)
  def usable_api_key? = api_key&.active? && api_key.user.customer? && !api_key.user.deactivated?
end
