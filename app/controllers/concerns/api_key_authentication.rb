module APIKeyAuthentication
  extend ActiveSupport::Concern

  include AbstractController::Translation

  private

  def api_key_error(api_key)
    return t('api_keys.errors.missing') if request_token.blank?
    return t('api_keys.errors.invalid') if api_key.blank? || api_key.user&.deactivated?

    t('api_keys.errors.expired', at: api_key.expires_at.iso8601, name: api_key.name) if api_key.expired?
  end

  def request_token
    @request_token ||= request.headers['X-API-Key'].presence || ActionController::HttpAuthentication::Token.token_and_options(request)&.first
  end
end
