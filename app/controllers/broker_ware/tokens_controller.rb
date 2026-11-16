class BrokerWare::TokensController < BrokerWare::ApplicationController
  BASIC = ActionController::HttpAuthentication::Basic
  GRANT_TYPE = 'client_credentials'.freeze

  skip_before_action :authenticate

  before_action :set_no_store

  def create
    if client_id.blank? || client_secret.blank? || params[:grant_type].blank?
      render_oauth_error('invalid_request', status: :bad_request)
      return
    end

    if params[:grant_type] != GRANT_TYPE
      render_oauth_error('unsupported_grant_type', status: :bad_request)
      return
    end

    @api_key = APIKey.authenticate(client_secret, client_id:)

    unless usable_api_key?
      render_oauth_error('invalid_client', status: :unauthorized)
      return
    end

    api_key.use!
  end

  private

  def basic_credentials
    return @basic_credentials if defined?(@basic_credentials)

    @basic_credentials = BASIC.has_basic_credentials?(request) ? BASIC.user_name_and_password(request) : []
  end

  def client_id = params[:client_id].presence || basic_credentials.first
  def client_secret = params[:client_secret].presence || basic_credentials.second
  def render_oauth_error(error, status:) = render(:error, locals: { error: }, status:)
  def set_no_store = response.headers['Cache-Control'] = 'no-store'
end
